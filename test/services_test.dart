import 'package:flutter_test/flutter_test.dart';
import 'package:match_and_sort_for_kids/data/catalog.dart';
import 'package:match_and_sort_for_kids/models/game_models.dart';
import 'package:match_and_sort_for_kids/services/rewards_service.dart';
import 'package:match_and_sort_for_kids/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('settings persist and reload', () {
    final s = SettingsController(prefs)
      ..update((x) {
        x.ageGroup = AgeGroup.smart;
        x.voice = true;
        x.disabledGames.add('color_sort');
        x.labelOverrides['everyday_foods'] = {'sometimes': 'Treat Foods'};
      });
    final again = SettingsController(prefs);
    expect(again.ageGroup, AgeGroup.smart);
    expect(again.voice, isTrue);
    expect(again.isGameEnabled('color_sort'), isFalse);
    expect(
      again.label('everyday_foods', 'sometimes', 'Sometimes Foods'),
      'Treat Foods',
    );
    expect(s.label('x', 'y', 'Fallback'), 'Fallback');
  });

  test('invalid stored settings fall back to safe defaults', () async {
    SharedPreferences.setMockInitialValues({
      'settings_v1':
          '{"age":"martian","level":9,"timerSeconds":-5,"disabledGames":"oops"}',
    });
    final p = await SharedPreferences.getInstance();
    final s = SettingsController(p);
    expect(s.ageGroup, AgeGroup.little);
    expect(s.fixedLevel, isNull);
    expect(s.timerSeconds, 30);
    SharedPreferences.setMockInitialValues({'settings_v1': 'not json {'});
    final s2 = SettingsController(await SharedPreferences.getInstance());
    expect(s2.timerEnabled, isFalse);
  });

  test('a round reports its stars and completes only once', () {
    final settings = SettingsController(prefs);
    final r = RewardsController(prefs);
    final game = allGames.first;
    for (final item in ['a', 'b', 'c', 'd']) {
      r.awardStar('s1', item);
    }
    final a = r.completeRound(
      sessionId: 's1',
      game: game,
      level: Level.veryEasy,
      correct: 4,
      mistakes: 0,
      settings: settings,
    );
    final b = r.completeRound(
      sessionId: 's1',
      game: game,
      level: Level.veryEasy,
      correct: 4,
      mistakes: 0,
      settings: settings,
    );
    expect(identical(a, b), isTrue);
    expect(a.stars, 4);
    // Finishing a round adds no extra currency - stars come from answers.
    expect(r.stars, 4);
    expect(r.roundsCompleted, 1);
  });

  test('one star per right answer, never twice, never taken away', () {
    final r = RewardsController(prefs);
    expect(r.awardStar('s', 'apple'), isTrue);
    expect(r.awardStar('s', 'apple'), isFalse);
    expect(r.awardStar('s2', 'apple'), isTrue);
    expect(r.stars, 2);
  });

  test('old saved points carry over as stars', () async {
    SharedPreferences.setMockInitialValues({
      'rewards_v1': '{"points":12,"coins":40,"stars":3,"xp":99}',
    });
    final r = RewardsController(await SharedPreferences.getInstance());
    expect(r.stars, 12);
  });

  test('stars persist across restarts', () {
    final settings = SettingsController(prefs);
    final first = RewardsController(prefs)..awardStar('x', 'apple');
    first.completeRound(
      sessionId: 'x',
      game: allGames.first,
      level: Level.veryEasy,
      correct: 4,
      mistakes: 0,
      settings: settings,
    );
    final again = RewardsController(prefs);
    expect(again.stars, 1);
    expect(again.progress[allGames.first.id]!.rounds, 1);
  });

  test('adaptive difficulty moves up after two smooth rounds', () {
    final settings = SettingsController(prefs);
    final r = RewardsController(prefs);
    final g = allGames.first;
    expect(r.levelFor(g, settings), Level.veryEasy);
    r.completeRound(
      sessionId: '1',
      game: g,
      level: Level.veryEasy,
      correct: 4,
      mistakes: 0,
      settings: settings,
    );
    final second = r.completeRound(
      sessionId: '2',
      game: g,
      level: Level.veryEasy,
      correct: 4,
      mistakes: 1,
      settings: settings,
    );
    expect(second.levelUp, Level.easy);
    expect(r.levelFor(g, settings), Level.easy);
    // A fixed parent choice always wins.
    settings.update((s) => s.fixedLevel = 3);
    expect(r.levelFor(g, settings), Level.explorer);
  });

  test('daily limit and extra time', () {
    final settings = SettingsController(prefs)
      ..update((s) => s.dailyLimitMinutes = 5);
    final r = RewardsController(prefs);
    r.addPlaySeconds(5 * 60);
    expect(r.dailyLimitReached(settings), isTrue);
    r.grantExtraTime(15);
    expect(r.dailyLimitReached(settings), isFalse);
  });

  test('corrupt rewards data does not crash', () async {
    SharedPreferences.setMockInitialValues({
      'rewards_v1': '{"stars":"many","progress":[1,2]}',
    });
    final r = RewardsController(await SharedPreferences.getInstance());
    expect(r.stars, 0);
  });
}
