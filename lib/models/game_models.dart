import 'package:flutter/painting.dart';

import 'visual.dart';

enum GameKind { sort, match }

/// Home-screen sections.
enum GameSection {
  colorShape('Colours & Shapes', '🎨'),
  bigSmall('Big & Small', '🐘'),
  food('Food & Kitchen', '🍎'),
  clothes('Clothes & Everyday', '👕'),
  animals('Animals & Nature', '🦁'),
  weather('Weather & Seasons', '🌦️'),
  letters('Letters & Words', '🔤'),
  puzzles('Matching Puzzles', '🧩'),
  science('Early Science', '🔬'),
  patterns('Patterns & Numbers', '🔢');

  const GameSection(this.title, this.emoji);
  final String title;
  final String emoji;
}

/// The scene a game is played in.
class GameTheme {
  const GameTheme({
    required this.top,
    required this.bottom,
    required this.ground,
    this.decorations = const [],
  });

  final Color top;
  final Color bottom;
  final Color ground;

  /// Non-interactive emoji placed around the edges of the scene.
  final List<String> decorations;
}

/// Difficulty levels. Difficulty changes how many things appear and how
/// varied they are, never how small the touch targets get.
enum Level {
  veryEasy(1, 'Very Easy', '🌱'),
  easy(2, 'Easy', '🌼'),
  explorer(3, 'Explorer', '🚀');

  const Level(this.value, this.label, this.emoji);
  final int value;
  final String label;
  final String emoji;

  static Level fromValue(int v) =>
      Level.values.firstWhere((l) => l.value == v, orElse: () => veryEasy);
}

/// Per-level numbers: index 0 = Very Easy, 1 = Easy, 2 = Explorer.
class LevelValues {
  const LevelValues(this.veryEasy, this.easy, this.explorer);
  final int veryEasy;
  final int easy;
  final int explorer;
  int of(Level l) => switch (l) {
    Level.veryEasy => veryEasy,
    Level.easy => easy,
    Level.explorer => explorer,
  };
}

sealed class GameDef {
  const GameDef({
    required this.id,
    required this.number,
    required this.title,
    required this.instruction,
    required this.section,
    required this.cover,
    required this.theme,
    this.minAge = 3,
    this.celebration,
    this.parentNote,
  });

  final String id;

  /// Catalog number (1-48), matches the product spec.
  final int number;
  final String title;

  /// One short instruction, readable aloud.
  final String instruction;
  final GameSection section;
  final String cover;
  final GameTheme theme;

  /// Recommended starting age. Never blocks play; parents decide.
  final int minAge;
  final String? celebration;

  /// Extra guidance shown to grown-ups in the Parent Zone.
  final String? parentNote;

  GameKind get kind;
}

// ---------------------------------------------------------------- sorting

class GameCategory {
  const GameCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.minLevel = 1,
  });

  final String id;
  final String label;
  final Visual icon;
  final Color color;

  /// The level at which this category is first introduced.
  final int minLevel;
}

class SortItem {
  const SortItem({
    required this.id,
    required this.name,
    required this.visual,
    required this.categoryId,
    this.minLevel = 1,
    this.fact,
    this.group,
  });

  final String id;
  final String name;
  final Visual visual;

  /// Optional theme group. When a game's items have groups, each round
  /// uses a single group (e.g. only animals or only vehicles).
  final String? group;

  /// Exactly one intended category per item within a game.
  final String categoryId;

  /// Harder or less familiar items only show up from this level.
  final int minLevel;

  /// Optional short spoken explanation after a correct sort.
  final String? fact;
}

class SortGameDef extends GameDef {
  const SortGameDef({
    required super.id,
    required super.number,
    required super.title,
    required super.instruction,
    required super.section,
    required super.cover,
    required super.theme,
    required this.categories,
    required this.items,
    super.minAge,
    super.celebration,
    super.parentNote,
    this.categoryCounts = const LevelValues(2, 2, 3),
    this.itemCounts = const LevelValues(4, 6, 8),
    this.activeCounts = const LevelValues(2, 3, 4),
    this.fixedCoreCategories = true,
  });

  final List<GameCategory> categories;
  final List<SortItem> items;
  final LevelValues categoryCounts;
  final LevelValues itemCounts;

  /// How many items are visible in the tray at once.
  final LevelValues activeCounts;

  /// When true, Very Easy always uses the first categories in list order
  /// (e.g. red and blue for colour sorting).
  final bool fixedCoreCategories;

  @override
  GameKind get kind => GameKind.sort;
}

// ---------------------------------------------------------------- matching

/// What two cards must share to count as a match. The engine only ever
/// compares [MatchCard.key]; the rule documents what that key means.
enum MatchRule {
  imageId('same picture'),
  colorId('same colour'),
  shapeId('same shape'),
  silhouetteId('object and its shadow'),
  letterId('same letter'),
  initialLetter('starts with the letter'),
  initialSound('starts with the sound'),
  familyId('animal family'),
  homeId('animal home'),
  habitatId('animal habitat'),
  soundId('animal sound'),
  weatherId('fits the weather'),
  outfitId('outfit set'),
  quantity('number and amount'),
  useId('what it is used for'),
  roomId('room it belongs in'),
  halfId('two halves'),
  patternNext('what comes next'),
  colorWord('colour word'),
  timeOfDay('day or night'),
  appearanceId('same markings');

  const MatchRule(this.description);
  final String description;
}

enum MatchLayout {
  /// All cards visible; tap two that belong together.
  board,

  /// One prompt card, two to four answer choices.
  prompt,
}

class MatchCard {
  const MatchCard({
    required this.id,
    required this.name,
    required this.visual,
    required this.key,
    this.spoken,
  });

  final String id;
  final String name;
  final Visual visual;
  final String key;

  /// What the voice says when the card is tapped (letter sounds etc.).
  final String? spoken;
}

class MatchPair {
  const MatchPair(this.a, this.b, {this.minLevel = 1, this.distractors});

  /// Board: one of the two cards. Prompt: the prompt card.
  final MatchCard a;

  /// Board: the partner card. Prompt: the correct answer.
  final MatchCard b;
  final int minLevel;

  /// Prompt mode: explicit wrong answers (pattern rounds); otherwise the
  /// engine picks answers of other pairs that have a different key.
  final List<MatchCard>? distractors;
}

typedef PairGenerator = List<MatchPair> Function(int seed, Level level);

class MatchGameDef extends GameDef {
  const MatchGameDef({
    required super.id,
    required super.number,
    required super.title,
    required super.instruction,
    required super.section,
    required super.cover,
    required super.theme,
    required this.rule,
    required this.layout,
    this.pairs = const [],
    this.generator,
    super.minAge,
    super.celebration,
    super.parentNote,
    this.twoColumns = true,
    this.pairCounts = const LevelValues(2, 3, 4),
    this.roundCounts = const LevelValues(4, 5, 6),
    this.choiceCounts = const LevelValues(2, 3, 3),
  });

  final MatchRule rule;
  final MatchLayout layout;
  final List<MatchPair> pairs;

  /// Procedural content (patterns). Takes precedence over [pairs].
  final PairGenerator? generator;

  /// Board: show "a" cards on the left and "b" cards on the right.
  /// False mixes everything in one grid (identical pictures, socks).
  final bool twoColumns;
  final LevelValues pairCounts;
  final LevelValues roundCounts;
  final LevelValues choiceCounts;

  @override
  GameKind get kind => GameKind.match;
}
