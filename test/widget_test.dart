import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_and_sort_for_kids/data/catalog.dart';
import 'package:match_and_sort_for_kids/engine/match_engine.dart';
import 'package:match_and_sort_for_kids/engine/sort_engine.dart';
import 'package:match_and_sort_for_kids/main.dart';
import 'package:match_and_sort_for_kids/models/game_models.dart';
import 'package:match_and_sort_for_kids/screens/celebration_screen.dart';
import 'package:match_and_sort_for_kids/screens/game_router.dart';
import 'package:match_and_sort_for_kids/screens/home_screen.dart';
import 'package:match_and_sort_for_kids/screens/match_board_screen.dart';
import 'package:match_and_sort_for_kids/screens/match_prompt_screen.dart';
import 'package:match_and_sort_for_kids/screens/sort_game_screen.dart';
import 'package:match_and_sort_for_kids/services/app_scope.dart';
import 'package:match_and_sort_for_kids/services/audio_service.dart';
import 'package:match_and_sort_for_kids/services/rewards_service.dart';
import 'package:match_and_sort_for_kids/services/settings_service.dart';
import 'package:match_and_sort_for_kids/widgets/clay.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Harness {
  Harness(this.settings, this.rewards);
  final SettingsController settings;
  final RewardsController rewards;
}

Future<Harness> pumpApp(
  WidgetTester tester, {
  Widget? home,
  Size size = const Size(390, 844),
  bool drag = false,
  int? level,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(prefs)
    ..update((s) {
      s.reducedMotion = true;
      s.autoHints = false;
      s.interaction = drag
          ? InteractionMode.tapAndDrag
          : InteractionMode.tapOnly;
      s.fixedLevel = level;
    });
  final rewards = RewardsController(prefs);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final app = MatchAndSortApp(
    settings: settings,
    rewards: rewards,
    audio: SilentAudio(),
  );
  if (home == null) {
    await tester.pumpWidget(app);
  } else {
    await tester.pumpWidget(
      AppScope(
        settings: settings,
        rewards: rewards,
        audio: SilentAudio(),
        child: MaterialApp(home: home),
      ),
    );
  }
  await tester.pump(const Duration(milliseconds: 100));
  return Harness(settings, rewards);
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

dynamic stateOf(WidgetTester tester, Type t) => tester.state(find.byType(t));

void main() {
  testWidgets('home shows sorting and matching games', (tester) async {
    await pumpApp(tester);
    expect(find.byType(FunkyGameCard), findsWidgets);
    expect(find.text('Colour Sorting'), findsOneWidget);
    await tester.tap(find.text('Match'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Colour Match'), findsOneWidget);
    await finish(tester);
  });

  // Stars are the only reward: no moons, coins, badges, XP or streaks.
  const banned = [
    '🌙',
    '🪙',
    '🏅',
    '🎖',
    '🏆',
    '💜',
    '🔥',
    'coin',
    'badge',
    'XP',
  ];
  List<String> visibleText(WidgetTester tester) => [
    for (final e in find.byType(Text).evaluate())
      (e.widget as Text).data ??
          (e.widget as Text).textSpan?.toPlainText() ??
          '',
  ];

  testWidgets('home shows only a star reward', (tester) async {
    await pumpApp(tester);
    final texts = visibleText(tester);
    for (final b in banned) {
      expect(texts.where((t) => t.contains(b)), isEmpty, reason: b);
    }
    expect(find.byType(ClayPill), findsOneWidget);
    expect(find.widgetWithText(ClayPill, '0'), findsOneWidget);
    await finish(tester);
  });

  testWidgets(
    'celebration gives only stars, even with level-up and break notes',
    (tester) async {
      final h = await pumpApp(
        tester,
        home: CelebrationScreen(
          game: allGames.first,
          title: 'Amazing Sorting!',
          completed: 4,
          reward: const RoundReward(stars: 4, levelUp: Level.easy),
        ),
      );
      h.rewards.sessionSeconds = 99999;
      tester.element(find.byType(CelebrationScreen)).markNeedsBuild();
      await tester.pump();
      expect(find.textContaining('rest your eyes'), findsOneWidget);
      expect(find.textContaining('Ready for Easy'), findsOneWidget);
      final texts = visibleText(tester);
      for (final b in banned) {
        expect(
          texts.where((t) => t.toLowerCase().contains(b.toLowerCase())),
          isEmpty,
          reason: b,
        );
      }
      expect(find.byType(ClayPill), findsOneWidget);
      expect(find.text('+4'), findsOneWidget);
      await finish(tester);
    },
  );

  testWidgets('parent zone is protected by the gate', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.lock_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Grown-ups only'), findsOneWidget);
    // A wrong answer keeps the gate closed.
    await tester.tap(find.text('1'));
    await tester.tap(find.text('✓'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Grown-ups only'), findsOneWidget);
    expect(find.text('Parent Zone'), findsNothing);
    // Answer correctly.
    final q = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.contains('×'));
    final parts = RegExp(r'(\d+) × (\d+)').firstMatch(q)!;
    final answer = int.parse(parts[1]!) * int.parse(parts[2]!);
    for (final d in '$answer'.split('')) {
      await tester.tap(find.text(d).last);
    }
    await tester.tap(find.text('✓'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Parent Zone'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a game opens with its intro the first time', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.text('Colour Sorting'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text("Let's Play!"), findsOneWidget);
    await tester.tap(find.text("Let's Play!"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SortGameScreen), findsOneWidget);
    expect(h.settings.seenIntros, contains('color_sort'));
    await finish(tester);
  });

  testWidgets(
    'sort game: tap-to-place completes a round with no lost rewards',
    (tester) async {
      final game =
          allGames.firstWhere((g) => g.id == 'fruit_veg') as SortGameDef;
      final h = await pumpApp(tester, home: SortGameScreen(game: game));
      final session = stateOf(tester, SortGameScreen).session as SortSession;

      // A wrong try first: nothing is lost and the item stays.
      final first = session.hintItem!;
      final wrong = session.round.categories.firstWhere(
        (c) => c.id != first.categoryId,
      );
      await tester.tap(find.byKey(ValueKey(first.id)));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(RegExp('^${wrong.label} basket')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(session.sortedCount, 0);
      expect(h.rewards.stars, 0);

      while (!session.isComplete) {
        final item = session.hintItem!;
        final cat = session.categoryOf(item);
        await tester.tap(find.byKey(ValueKey(item.id)));
        await tester.pump();
        await tester.tap(find.bySemanticsLabel(RegExp('^${cat.label} basket')));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Amazing Sorting!'), findsWidgets);
      expect(find.text('Play Again'), findsOneWidget);
      expect(h.rewards.stars, session.total);
      expect(find.text('+${session.total}'), findsOneWidget);
      await finish(tester);
    },
  );

  testWidgets('sort game: drag-and-drop works and misses float back', (
    tester,
  ) async {
    final game =
        allGames.firstWhere((g) => g.id == 'color_sort') as SortGameDef;
    await pumpApp(tester, home: SortGameScreen(game: game), drag: true);
    final session = stateOf(tester, SortGameScreen).session as SortSession;
    final item = session.hintItem!;
    final cat = session.categoryOf(item);

    // Dropped in empty space: nothing happens.
    await tester.drag(find.byKey(ValueKey(item.id)), const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 500));
    expect(session.sortedCount, 0);
    expect(session.slots.any((s) => s?.id == item.id), isTrue);

    final from = tester.getCenter(find.byKey(ValueKey(item.id)));
    final to = tester.getCenter(
      find.bySemanticsLabel(RegExp('^${cat.label} basket')),
    );
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(session.sortedCount, 1);
    await finish(tester);
  });

  testWidgets('match board: pairs complete the round', (tester) async {
    final game =
        allGames.firstWhere((g) => g.id == 'upper_lower_match') as MatchGameDef;
    final h = await pumpApp(tester, home: MatchBoardScreen(game: game));
    final session = stateOf(tester, MatchBoardScreen).session as BoardSession;
    for (final p in session.round.pairs) {
      await tester.tap(find.byKey(ValueKey(p.a.id)));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey(p.b.id)));
      await tester.pump(const Duration(milliseconds: 900));
    }
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Wonderful Matching!'), findsWidgets);
    expect(h.rewards.stars, session.total);
    await finish(tester);
  });

  testWidgets('match prompt: answering every step completes the round', (
    tester,
  ) async {
    final game =
        allGames.firstWhere((g) => g.id == 'letter_object') as MatchGameDef;
    await pumpApp(tester, home: MatchPromptScreen(game: game));
    final session = stateOf(tester, MatchPromptScreen).session as PromptSession;
    var guard = 0;
    while (!session.isComplete && guard++ < 20) {
      final st = session.current!;
      await tester.tap(
        find
            .bySemanticsLabel(RegExp('^${RegExp.escape(st.answer.name)}'))
            .first,
      );
      await tester.pump(const Duration(milliseconds: 900));
    }
    expect(session.isComplete, isTrue);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Wonderful Matching!'), findsWidgets);
    await finish(tester);
  });

  testWidgets('pause freezes the timer and resumes', (tester) async {
    final game = allGames.first;
    final h = await pumpApp(tester);
    h.settings.update((s) {
      s.timerEnabled = true;
      s.timerSeconds = 60;
    });
    h.settings.markIntroSeen(game.id);
    await tester.tap(find.text(game.title));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('58'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('58'), findsOneWidget);
    await tester.tap(find.text('Keep Playing'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('57'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('4 colour baskets fit while one glows on a small phone', (
    tester,
  ) async {
    final game =
        allGames.firstWhere((g) => g.id == 'color_sort') as SortGameDef;
    await pumpApp(
      tester,
      home: SortGameScreen(game: game),
      size: const Size(375, 667),
      level: 3,
    );
    final session = stateOf(tester, SortGameScreen).session as SortSession;
    expect(session.round.categories.length, 4);
    // A wrong try makes the right basket glow with its white border.
    final item = session.hintItem!;
    final wrong = session.round.categories.firstWhere(
      (c) => c.id != item.categoryId,
    );
    await tester.tap(find.byKey(ValueKey(item.id)));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(RegExp('^${wrong.label} basket')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  // Every activity must open and render on a small phone without overflow,
  // at both the simplest and the busiest level.
  for (final game in allGames) {
    testWidgets(
      '#${game.number} ${game.id} renders on a small screen at Explorer',
      (tester) async {
        await pumpApp(
          tester,
          home: gameScreenFor(game),
          size: const Size(320, 568),
          level: 3,
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        await finish(tester);
      },
    );
  }
  for (final game in allGames) {
    testWidgets('#${game.number} ${game.id} renders on a small screen', (
      tester,
    ) async {
      await pumpApp(
        tester,
        home: gameScreenFor(game),
        size: const Size(320, 568),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  }
}
