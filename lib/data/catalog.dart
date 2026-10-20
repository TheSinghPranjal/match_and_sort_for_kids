import '../models/game_models.dart';
import 'match_games.dart';
import 'sort_games.dart';

/// Every activity in the app, sorted by catalog number.
final List<GameDef> allGames = [...sortGames, ...matchGames]
  ..sort((a, b) => a.number.compareTo(b.number));

GameDef? gameById(String id) {
  for (final g in allGames) {
    if (g.id == id) return g;
  }
  return null;
}

/// Static content checks. Returns human-readable problems (empty = valid).
/// Run by the test suite so broken content never ships.
List<String> validateCatalog() {
  final problems = <String>[];
  final ids = <String>{};
  final numbers = <int>{};
  for (final g in allGames) {
    if (!ids.add(g.id)) problems.add('Duplicate game id ${g.id}');
    if (!numbers.add(g.number)) problems.add('Duplicate number ${g.number}');
    switch (g) {
      case SortGameDef():
        problems.addAll(_validateSort(g));
      case MatchGameDef():
        problems.addAll(_validateMatch(g));
    }
  }
  return problems;
}

List<String> _validateSort(SortGameDef g) {
  final p = <String>[];
  final catIds = <String>{};
  for (final c in g.categories) {
    if (!catIds.add(c.id)) p.add('${g.id}: duplicate category ${c.id}');
  }
  if (g.categories.length < 2) p.add('${g.id}: needs at least 2 categories');
  final itemIds = <String>{};
  for (final i in g.items) {
    if (!itemIds.add(i.id)) p.add('${g.id}: duplicate item ${i.id}');
    if (!catIds.contains(i.categoryId)) {
      p.add('${g.id}: item ${i.id} points to missing ${i.categoryId}');
    }
  }
  for (final level in Level.values) {
    final cats = g.categories.where((c) => c.minLevel <= level.value);
    if (cats.length < 2) p.add('${g.id}: <2 categories at ${level.name}');
    for (final c in cats) {
      final n = g.items
          .where((i) => i.categoryId == c.id && i.minLevel <= level.value)
          .length;
      if (n == 0) p.add('${g.id}: category ${c.id} empty at ${level.name}');
    }
  }
  return p;
}

List<String> _validateMatch(MatchGameDef g) {
  final p = <String>[];
  if (g.generator != null) return p;
  if (g.pairs.isEmpty) p.add('${g.id}: no pairs');
  final cardIds = <String, String>{};
  for (final pair in g.pairs) {
    if (pair.a.key != pair.b.key) {
      p.add('${g.id}: pair ${pair.a.id}/${pair.b.id} keys differ');
    }
    for (final c in [pair.a, pair.b]) {
      // The same answer card may be reused (e.g. one "Day" scene), but an
      // id must always mean the same key.
      final prev = cardIds[c.id];
      if (prev != null && prev != c.key) {
        p.add('${g.id}: card id ${c.id} reused with a different key');
      }
      cardIds[c.id] = c.key;
    }
  }
  for (final level in Level.values) {
    final avail = g.pairs.where((x) => x.minLevel <= level.value).toList();
    if (g.layout == MatchLayout.board) {
      final keys = avail.map((x) => x.a.key).toSet();
      if (keys.length < 2) p.add('${g.id}: <2 pairs at ${level.name}');
    } else {
      final answerKeys = avail.map((x) => x.b.key).toSet();
      if (answerKeys.length < 2) {
        p.add('${g.id}: <2 distinct answers at ${level.name}');
      }
    }
  }
  return p;
}
