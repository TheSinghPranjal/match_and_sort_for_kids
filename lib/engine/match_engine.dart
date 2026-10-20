import 'dart:math';

import '../models/game_models.dart';

/// Matching logic shared by all 23 matching activities. Answers are never
/// encoded in widget layout: two cards match only when their keys are equal
/// (see [MatchRule]).
class MatchEngine {
  MatchEngine._();

  static bool isMatch(MatchCard a, MatchCard b) =>
      a.id != b.id && a.key == b.key;

  static List<MatchPair> availablePairs(
    MatchGameDef game,
    Level level,
    int seed, {
    Set<String> disabledKeys = const {},
  }) {
    final source = game.generator?.call(seed, level) ?? game.pairs;
    final all = source.where((p) => p.minLevel <= level.value).toList();
    final filtered = all.where((p) => !disabledKeys.contains(p.a.key)).toList();
    final distinct = filtered.map((p) => p.b.key).toSet().length;
    // Too much switched off by a parent? Use the safe default set.
    return distinct >= 2 ? filtered : all;
  }

  static BoardRound buildBoard(
    MatchGameDef game,
    Level level,
    Random rnd, {
    Set<String> disabledKeys = const {},
  }) {
    final pairs = [
      ...availablePairs(
        game,
        level,
        rnd.nextInt(1 << 30),
        disabledKeys: disabledKeys,
      ),
    ]..shuffle(rnd);
    // One pair per key so there is never more than one right partner.
    final chosen = <MatchPair>[];
    final keys = <String>{};
    for (final p in pairs) {
      if (chosen.length >= game.pairCounts.of(level)) break;
      if (keys.add(p.a.key)) chosen.add(p);
    }
    final left = [for (final p in chosen) p.a]..shuffle(rnd);
    final right = [for (final p in chosen) p.b]..shuffle(rnd);
    // Avoid lining partners up directly across from each other.
    if (game.twoColumns && right.length > 1) {
      for (var i = 0; i < 4 && _aligned(left, right); i++) {
        right.shuffle(rnd);
      }
    }
    final grid = [...left, ...right]..shuffle(rnd);
    return BoardRound(
      game: game,
      level: level,
      pairs: chosen,
      left: game.twoColumns ? left : grid,
      right: game.twoColumns ? right : const [],
    );
  }

  static bool _aligned(List<MatchCard> l, List<MatchCard> r) {
    for (var i = 0; i < l.length; i++) {
      if (l[i].key != r[i].key) return false;
    }
    return true;
  }

  static PromptRound buildPrompts(
    MatchGameDef game,
    Level level,
    Random rnd, {
    Set<String> disabledKeys = const {},
  }) {
    final pairs = availablePairs(
      game,
      level,
      rnd.nextInt(1 << 30),
      disabledKeys: disabledKeys,
    );
    final rounds = game.roundCounts.of(level);
    final choiceCount = game.choiceCounts.of(level);
    final steps = <PromptStep>[];
    var deck = <MatchPair>[];
    String? lastPrompt;
    var guard = 0;
    while (steps.length < rounds && guard++ < rounds * 10) {
      if (deck.isEmpty) deck = [...pairs]..shuffle(rnd);
      final pair = deck.removeLast();
      if (pair.a.id == lastPrompt && pairs.length > 1) continue;
      final step = _step(pair, pairs, choiceCount, rnd);
      if (step == null) continue;
      steps.add(step);
      lastPrompt = pair.a.id;
    }
    return PromptRound(game: game, level: level, steps: steps);
  }

  static PromptStep? _step(
    MatchPair pair,
    List<MatchPair> pool,
    int choiceCount,
    Random rnd,
  ) {
    final answer = pair.b;
    final seenKeys = {answer.key};
    final distractors = <MatchCard>[];
    final candidates =
        pair.distractors ?? ([for (final p in pool) p.b]..shuffle(rnd));
    for (final c in candidates) {
      if (distractors.length >= choiceCount - 1) break;
      if (seenKeys.add(c.key)) distractors.add(c);
    }
    if (distractors.isEmpty) return null;
    final choices = [answer, ...distractors]..shuffle(rnd);
    return PromptStep(prompt: pair.a, choices: choices, answer: answer);
  }
}

class BoardRound {
  const BoardRound({
    required this.game,
    required this.level,
    required this.pairs,
    required this.left,
    required this.right,
  });

  final MatchGameDef game;
  final Level level;
  final List<MatchPair> pairs;

  /// Two-column games: "a" cards. Grid games: every card.
  final List<MatchCard> left;
  final List<MatchCard> right;

  bool get twoColumns => right.isNotEmpty;
  List<MatchCard> get allCards => [...left, ...right];
}

enum BoardOutcome { selected, switched, deselected, matched, tryAgain, ignored }

class BoardSession {
  BoardSession(this.round);

  final BoardRound round;
  String? selectedId;
  final Set<String> matchedIds = {};
  final Set<String> _matchedKeys = {};
  int mistakes = 0;

  /// The pair that was just compared (for animations).
  (MatchCard, MatchCard)? lastPair;

  int get total => round.pairs.length;
  int get matchedCount => _matchedKeys.length;
  bool get isComplete => matchedCount == total;

  MatchCard card(String id) => round.allCards.firstWhere((c) => c.id == id);

  bool _sameColumn(String a, String b) {
    if (!round.twoColumns) return false;
    final inLeft = round.left.any((c) => c.id == a);
    return inLeft == round.left.any((c) => c.id == b);
  }

  /// A card that can be matched right now (for hints).
  MatchCard? partnerOf(String id) {
    final c = card(id);
    for (final o in round.allCards) {
      if (MatchEngine.isMatch(c, o) && !matchedIds.contains(o.id)) return o;
    }
    return null;
  }

  MatchCard? get hintCard {
    final sel = selectedId;
    if (sel != null) return partnerOf(sel);
    for (final c in round.allCards) {
      if (!matchedIds.contains(c.id)) return c;
    }
    return null;
  }

  BoardOutcome tap(String id) {
    if (matchedIds.contains(id)) return BoardOutcome.ignored;
    final sel = selectedId;
    if (sel == null) {
      selectedId = id;
      return BoardOutcome.selected;
    }
    if (sel == id) {
      selectedId = null;
      return BoardOutcome.deselected;
    }
    if (_sameColumn(sel, id)) {
      selectedId = id;
      return BoardOutcome.switched;
    }
    return tryPair(sel, id);
  }

  /// Compares two cards directly (also used by drag-and-drop).
  BoardOutcome tryPair(String aId, String bId) {
    if (aId == bId ||
        matchedIds.contains(aId) ||
        matchedIds.contains(bId) ||
        _sameColumn(aId, bId)) {
      return BoardOutcome.ignored;
    }
    final a = card(aId), b = card(bId);
    selectedId = null;
    lastPair = (a, b);
    if (MatchEngine.isMatch(a, b) && _matchedKeys.add(a.key)) {
      matchedIds
        ..add(a.id)
        ..add(b.id);
      return BoardOutcome.matched;
    }
    mistakes++;
    return BoardOutcome.tryAgain;
  }
}

class PromptStep {
  const PromptStep({
    required this.prompt,
    required this.choices,
    required this.answer,
  });

  final MatchCard prompt;
  final List<MatchCard> choices;
  final MatchCard answer;
}

class PromptRound {
  const PromptRound({
    required this.game,
    required this.level,
    required this.steps,
  });

  final MatchGameDef game;
  final Level level;
  final List<PromptStep> steps;
}

enum PromptOutcome { correct, tryAgain, ignored }

class PromptSession {
  PromptSession(this.round);

  final PromptRound round;
  int index = 0;
  int mistakes = 0;
  final Set<int> _solved = {};
  final Set<int> _missed = {};

  int get total => round.steps.length;
  int get solvedCount => _solved.length;
  int get firstTryCount => _solved.difference(_missed).length;
  bool get isComplete => solvedCount == total;
  PromptStep? get current => index < total ? round.steps[index] : null;

  PromptOutcome choose(String cardId) {
    final step = current;
    if (step == null || _solved.contains(index)) return PromptOutcome.ignored;
    final picked = step.choices.where((c) => c.id == cardId).firstOrNull;
    if (picked == null) return PromptOutcome.ignored;
    if (MatchEngine.isMatch(step.prompt, picked) ||
        picked.id == step.answer.id) {
      _solved.add(index);
      return PromptOutcome.correct;
    }
    mistakes++;
    _missed.add(index);
    return PromptOutcome.tryAgain;
  }

  /// Moves to the next prompt after the correct-answer animation.
  void advance() {
    if (_solved.contains(index)) index++;
  }
}
