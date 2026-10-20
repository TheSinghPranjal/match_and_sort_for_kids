import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_and_sort_for_kids/data/catalog.dart';
import 'package:match_and_sort_for_kids/data/match_games.dart';
import 'package:match_and_sort_for_kids/data/sort_games.dart';
import 'package:match_and_sort_for_kids/engine/match_engine.dart';
import 'package:match_and_sort_for_kids/engine/sort_engine.dart';
import 'package:match_and_sort_for_kids/models/game_models.dart';
import 'package:match_and_sort_for_kids/models/visual.dart';

MatchGameDef _match(String id) => matchGames.firstWhere((g) => g.id == id);

void main() {
  group('catalog', () {
    test('has all 48 activities numbered 1-48', () {
      expect(allGames.length, 48);
      expect(
        allGames.map((g) => g.number).toList(),
        List.generate(48, (i) => i + 1),
      );
      expect(sortGames.length, 25);
      expect(matchGames.length, 23);
    });

    test('content passes validation', () {
      expect(validateCatalog(), isEmpty);
    });

    test('every game is wired to an engine with a non-empty round', () {
      for (final g in allGames) {
        for (final level in Level.values) {
          switch (g) {
            case SortGameDef():
              expect(
                SortEngine.buildRound(g, level, Random(1)).items,
                isNotEmpty,
                reason: g.id,
              );
            case MatchGameDef(layout: MatchLayout.board):
              expect(
                MatchEngine.buildBoard(g, level, Random(1)).pairs.length,
                greaterThanOrEqualTo(2),
                reason: g.id,
              );
            case MatchGameDef():
              expect(
                MatchEngine.buildPrompts(g, level, Random(1)).steps,
                isNotEmpty,
                reason: g.id,
              );
          }
        }
      }
    });
  });

  group('sort engine', () {
    test('every game produces valid rounds at every level', () {
      for (final g in sortGames) {
        for (final level in Level.values) {
          for (var seed = 0; seed < 60; seed++) {
            final r = SortEngine.buildRound(g, level, Random(seed));
            final catIds = r.categories.map((c) => c.id).toSet();
            expect(r.categories.length, greaterThanOrEqualTo(2), reason: g.id);
            expect(catIds.length, r.categories.length);
            expect(
              r.items.map((i) => i.id).toSet().length,
              r.items.length,
              reason: 'dup items ${g.id}',
            );
            for (final i in r.items) {
              expect(catIds, contains(i.categoryId), reason: '${g.id}/${i.id}');
              expect(i.minLevel, lessThanOrEqualTo(level.value));
            }
            for (final c in r.categories) {
              expect(
                r.items.any((i) => i.categoryId == c.id),
                isTrue,
                reason: 'empty basket ${g.id}/${c.id}',
              );
              expect(c.minLevel, lessThanOrEqualTo(level.value));
            }
            final groups = r.items.map((i) => i.group).toSet();
            expect(groups.length, 1, reason: 'mixed groups in ${g.id}');
          }
        }
      }
    });

    test('Very Easy colour sorting starts with red and blue', () {
      final g = sortGames.firstWhere((g) => g.id == 'color_sort');
      final r = SortEngine.buildRound(g, Level.veryEasy, Random(3));
      expect(r.categories.map((c) => c.id), ['red', 'blue']);
      expect(r.items.length, 4);
    });

    test('correct placements score once; wrong ones never score', () {
      final g = sortGames.firstWhere((g) => g.id == 'fruit_veg');
      final s = SortSession(SortEngine.buildRound(g, Level.easy, Random(5)));
      final item = s.hintItem!;
      final wrong = s.round.categories.firstWhere(
        (c) => c.id != item.categoryId,
      );
      expect(s.place(item.id, wrong.id), SortOutcome.tryAgain);
      expect(s.sortedCount, 0);
      expect(
        s.slots.any((x) => x?.id == item.id),
        isTrue,
        reason: 'item returns to tray',
      );
      expect(s.place(item.id, item.categoryId), SortOutcome.correct);
      expect(s.place(item.id, item.categoryId), SortOutcome.ignored);
      expect(s.sortedCount, 1);
      expect(s.mistakes, 1);
    });

    test('a full session completes', () {
      for (final g in sortGames) {
        final s = SortSession(
          SortEngine.buildRound(g, Level.explorer, Random(9)),
        );
        var guard = 0;
        while (!s.isComplete && guard++ < 50) {
          final i = s.hintItem!;
          expect(s.place(i.id, i.categoryId), SortOutcome.correct);
        }
        expect(s.isComplete, isTrue, reason: g.id);
        expect(s.firstTryCount, s.total);
      }
    });

    test('disabled categories never become destinations', () {
      final g = sortGames.firstWhere((g) => g.id == 'color_sort');
      for (var seed = 0; seed < 40; seed++) {
        final r = SortEngine.buildRound(
          g,
          Level.explorer,
          Random(seed),
          disabledCategories: {'red', 'green'},
        );
        final ids = r.categories.map((c) => c.id);
        expect(ids, isNot(contains('red')));
        expect(ids, isNot(contains('green')));
        final s = SortSession(r);
        expect(s.isValidDestination('red'), isFalse);
      }
    });

    test('disabling everything falls back to safe defaults', () {
      final g = sortGames.firstWhere((g) => g.id == 'tops_bottoms');
      final r = SortEngine.buildRound(
        g,
        Level.veryEasy,
        Random(1),
        disabledItems: g.items.map((i) => i.id).toSet(),
        disabledCategories: g.categories.map((c) => c.id).toSet(),
      );
      expect(r.categories.length, 2);
      expect(r.items, isNotEmpty);
    });

    test('upper/lower letters use the same drawing size', () {
      final g = sortGames.firstWhere((g) => g.id == 'upper_lower_sort');
      for (final i in g.items) {
        expect(i.visual, isA<LetterVisual>());
      }
    });
  });

  group('match engine', () {
    test('boards have exactly one partner per card', () {
      for (final g in matchGames.where((g) => g.layout == MatchLayout.board)) {
        for (final level in Level.values) {
          for (var seed = 0; seed < 40; seed++) {
            final r = MatchEngine.buildBoard(g, level, Random(seed));
            for (final c in r.allCards) {
              final partners = r.allCards.where(
                (o) => MatchEngine.isMatch(c, o),
              );
              expect(partners.length, 1, reason: '${g.id}/${c.id}');
            }
          }
        }
      }
    });

    test('prompts have exactly one right answer and distinct choices', () {
      for (final g in matchGames.where((g) => g.layout == MatchLayout.prompt)) {
        for (final level in Level.values) {
          for (var seed = 0; seed < 40; seed++) {
            final r = MatchEngine.buildPrompts(g, level, Random(seed));
            expect(r.steps.length, g.roundCounts.of(level), reason: g.id);
            for (final st in r.steps) {
              expect(st.choices.length, greaterThanOrEqualTo(2), reason: g.id);
              expect(
                st.choices.where((c) => c.key == st.prompt.key).length,
                1,
                reason: '${g.id}/${st.prompt.id}',
              );
              expect(
                st.choices.map((c) => c.key).toSet().length,
                st.choices.length,
              );
            }
          }
        }
      }
    });

    test('uppercase and lowercase pairs are correct', () {
      for (final p in _match('upper_lower_match').pairs) {
        final upper = (p.a.visual as LetterVisual).text;
        final lower = (p.b.visual as LetterVisual).text;
        expect(lower, upper.toLowerCase());
        expect(p.a.key, upper);
      }
    });

    test('letter-to-object uses the initial letter', () {
      for (final p in _match('letter_object').pairs) {
        final letter = (p.a.visual as LetterVisual).text;
        expect(
          p.b.name.toUpperCase().startsWith(letter),
          isTrue,
          reason: p.b.name,
        );
      }
      expect(_match('letter_object').pairs.length, 26);
    });

    test('initial sounds keep letter names separate from sounds', () {
      for (final p in _match('initial_sounds').pairs) {
        final letter = (p.a.visual as LetterVisual).text;
        expect(p.b.name.toLowerCase().startsWith(letter), isTrue);
        expect(p.a.spoken, isNot(letter));
      }
    });

    test('weather-to-clothing pairs are configured sensibly', () {
      const expected = {
        'Raincoat': 'rain',
        'Umbrella': 'rain',
        'Sweater': 'cold',
        'Gloves': 'cold',
        'Scarf': 'cold',
        'Sun hat': 'sunny',
        'Cap': 'sunny',
        'Shorts': 'sunny',
      };
      for (final p in _match('weather_clothes_match').pairs) {
        expect(expected[p.b.name], p.b.key, reason: p.b.name);
        expect(p.a.key, p.b.key);
      }
    });

    test('animal habitats are validated', () {
      const expected = {
        'Camel': 'desert',
        'Dolphin': 'ocean',
        'Polar bear': 'arctic',
        'Monkey': 'forest',
        'Lion': 'savanna',
        'Frog': 'pond',
        'Deer': 'woodland',
        'Tiger': 'jungle',
      };
      for (final p in _match('habitats').pairs) {
        expect(p.b.key, expected[p.a.name], reason: p.a.name);
      }
    });

    test(
      'board: wrong match resets without losing progress; pairs award once',
      () {
        final g = _match('identical');
        final s = BoardSession(
          MatchEngine.buildBoard(g, Level.easy, Random(2)),
        );
        final first = s.round.pairs[0];
        final second = s.round.pairs[1];
        expect(s.tap(first.a.id), BoardOutcome.selected);
        expect(s.tap(first.b.id), BoardOutcome.matched);
        expect(s.matchedCount, 1);
        expect(s.tap(second.a.id), BoardOutcome.selected);
        expect(s.tap(s.round.pairs[2].a.id), BoardOutcome.tryAgain);
        expect(s.matchedCount, 1);
        expect(s.selectedId, isNull);
        // Matched cards can't match again.
        expect(s.tap(first.a.id), BoardOutcome.ignored);
        expect(s.tryPair(first.a.id, first.b.id), BoardOutcome.ignored);
        expect(s.matchedCount, 1);
      },
    );

    test('board: final pair completes the round', () {
      for (final g in matchGames.where((g) => g.layout == MatchLayout.board)) {
        final s = BoardSession(
          MatchEngine.buildBoard(g, Level.explorer, Random(4)),
        );
        for (final p in s.round.pairs) {
          expect(s.tryPair(p.a.id, p.b.id), BoardOutcome.matched, reason: g.id);
        }
        expect(s.isComplete, isTrue);
      }
    });

    test('two-column boards ignore taps on the same side', () {
      final g = _match('upper_lower_match');
      final s = BoardSession(MatchEngine.buildBoard(g, Level.easy, Random(1)));
      s.tap(s.round.left[0].id);
      expect(s.tap(s.round.left[1].id), BoardOutcome.switched);
      expect(s.mistakes, 0);
    });

    test('prompt session: wrong answers keep the step, right ones advance', () {
      for (final g in matchGames.where((g) => g.layout == MatchLayout.prompt)) {
        final s = PromptSession(
          MatchEngine.buildPrompts(g, Level.easy, Random(6)),
        );
        while (!s.isComplete) {
          final st = s.current!;
          final wrong = st.choices.firstWhere((c) => c.id != st.answer.id);
          expect(s.choose(wrong.id), PromptOutcome.tryAgain);
          expect(s.choose(st.answer.id), PromptOutcome.correct, reason: g.id);
          expect(s.choose(st.answer.id), PromptOutcome.ignored);
          s.advance();
        }
        expect(s.solvedCount, s.total);
        expect(s.firstTryCount, 0);
      }
    });

    test('patterns pick the right next element', () {
      for (var seed = 0; seed < 30; seed++) {
        for (final level in Level.values) {
          for (final p in generatePatterns(seed, level)) {
            final ids = (p.a.visual as SequenceVisual).items
                .map((v) => v.visualId)
                .toList();
            // ABAB? repeats every 2; AAB / ABB / ABC patterns every 3.
            final period =
                ids[0] == ids[2] && ids[1] == ids[3] && ids[0] != ids[1]
                ? 2
                : 3;
            expect(p.b.visual.visualId, ids[5 - period]);
            expect(p.distractors!.every((d) => d.key != p.b.key), isTrue);
          }
        }
      }
    });
  });
}
