import 'dart:math';

import '../models/game_models.dart';

/// A ready-to-play sorting round.
class SortRound {
  const SortRound({
    required this.game,
    required this.level,
    required this.categories,
    required this.items,
    required this.activeCount,
  });

  final SortGameDef game;
  final Level level;
  final List<GameCategory> categories;
  final List<SortItem> items;
  final int activeCount;
}

/// Builds sorting rounds from a [SortGameDef]. Shared by all 25 sorting
/// activities - games only differ in data.
class SortEngine {
  SortEngine._();

  static SortRound buildRound(
    SortGameDef game,
    Level level,
    Random rnd, {
    Set<String> disabledItems = const {},
    Set<String> disabledCategories = const {},
  }) {
    final round = _tryBuild(
      game,
      level,
      rnd,
      disabledItems,
      disabledCategories,
    );
    if (round != null) return round;
    // Parent settings left too little to play with: fall back to safe
    // defaults rather than failing.
    return _tryBuild(game, level, rnd, const {}, const {}) ??
        _tryBuild(game, Level.explorer, rnd, const {}, const {})!;
  }

  static SortRound? _tryBuild(
    SortGameDef game,
    Level level,
    Random rnd,
    Set<String> disabledItems,
    Set<String> disabledCategories,
  ) {
    var pool = game.items
        .where(
          (i) => i.minLevel <= level.value && !disabledItems.contains(i.id),
        )
        .toList();
    bool catAllowed(GameCategory c) =>
        c.minLevel <= level.value && !disabledCategories.contains(c.id);

    // Keep a round internally consistent (only animals, or only vehicles).
    final groups = pool.map((i) => i.group).whereType<String>().toSet();
    if (groups.isNotEmpty) {
      final eligible = groups.where((grp) {
        final cats = pool
            .where((i) => i.group == grp)
            .map((i) => i.categoryId)
            .toSet();
        return game.categories
                .where((c) => catAllowed(c) && cats.contains(c.id))
                .length >=
            2;
      }).toList()..sort();
      if (eligible.isEmpty) return null;
      final grp = eligible[rnd.nextInt(eligible.length)];
      pool = pool.where((i) => i.group == grp).toList();
    }

    final usedCats = pool.map((i) => i.categoryId).toSet();
    final available = game.categories
        .where((c) => catAllowed(c) && usedCats.contains(c.id))
        .toList();
    if (available.length < 2) return null;

    final count = game.categoryCounts.of(level).clamp(2, available.length);
    final List<GameCategory> chosen;
    if (game.fixedCoreCategories && level == Level.veryEasy) {
      chosen = available.take(count).toList();
    } else {
      chosen = ([...available]..shuffle(rnd)).take(count).toList();
      // Keep baskets in the game's natural order (e.g. Big before Small).
      chosen.sort(
        (a, b) =>
            game.categories.indexOf(a).compareTo(game.categories.indexOf(b)),
      );
    }

    // Round-robin across categories so every basket gets used.
    final perCat = {
      for (final c in chosen)
        c.id: (pool.where((i) => i.categoryId == c.id).toList()..shuffle(rnd)),
    };
    final target = game.itemCounts.of(level);
    final items = <SortItem>[];
    var added = true;
    while (items.length < target && added) {
      added = false;
      for (final c in chosen) {
        final list = perCat[c.id]!;
        if (list.isNotEmpty && items.length < target) {
          items.add(list.removeLast());
          added = true;
        }
      }
    }
    items.shuffle(rnd);

    return SortRound(
      game: game,
      level: level,
      categories: chosen,
      items: items,
      activeCount: game.activeCounts.of(level).clamp(1, items.length),
    );
  }
}

enum SortOutcome { correct, tryAgain, ignored }

/// Mutable state of one sorting round. Pure Dart so it is unit-testable.
class SortSession {
  SortSession(this.round)
    : _queue = [...round.items],
      slots = List<SortItem?>.filled(round.activeCount, null) {
    for (var i = 0; i < slots.length; i++) {
      slots[i] = _queue.isEmpty ? null : _queue.removeAt(0);
    }
  }

  final SortRound round;
  final List<SortItem> _queue;

  /// Items currently visible in the tray. `null` = empty slot.
  final List<SortItem?> slots;
  final Map<String, List<SortItem>> placed = {};
  final Set<String> _scored = {};
  final Set<String> _missed = {};
  int mistakes = 0;

  int get total => round.items.length;
  int get sortedCount => _scored.length;
  int get remaining => total - sortedCount;
  bool get isComplete => sortedCount == total;

  /// Items sorted right on the first attempt.
  int get firstTryCount => _scored.difference(_missed).length;

  bool isValidDestination(String categoryId) =>
      round.categories.any((c) => c.id == categoryId);

  GameCategory categoryOf(SortItem item) =>
      round.categories.firstWhere((c) => c.id == item.categoryId);

  SortItem? get hintItem {
    for (final s in slots) {
      if (s != null) return s;
    }
    return null;
  }

  SortOutcome place(String itemId, String categoryId) {
    final index = slots.indexWhere((s) => s?.id == itemId);
    if (index < 0) return SortOutcome.ignored;
    final item = slots[index]!;
    if (item.categoryId != categoryId || !isValidDestination(categoryId)) {
      mistakes++;
      _missed.add(item.id);
      return SortOutcome.tryAgain;
    }
    if (!_scored.add(item.id)) return SortOutcome.ignored;
    placed.putIfAbsent(categoryId, () => []).add(item);
    slots[index] = _queue.isEmpty ? null : _queue.removeAt(0);
    return SortOutcome.correct;
  }
}
