import 'package:flutter/painting.dart';

/// Describes how a game object is drawn. Content stays data-only; the
/// [ItemArt] widget turns a [Visual] into pixels. Every visual is drawn
/// from code or the system emoji font, so there are no asset files that
/// could go missing at runtime.
sealed class Visual {
  const Visual();

  /// Stable id used by identical-picture / pattern matching rules.
  String get visualId;
}

enum EmojiEffect { none, mud, silhouette, leftHalf, rightHalf, steam, frost }

class EmojiVisual extends Visual {
  const EmojiVisual(
    this.emoji, {
    this.scale = 1,
    this.effect = EmojiEffect.none,
    this.badge,
  });

  final String emoji;

  /// Relative drawing size inside a constant-size card (Big/Small games).
  /// Touch targets never shrink - only the drawing does.
  final double scale;
  final EmojiEffect effect;

  /// Optional small corner badge (e.g. "baby" heart, sparkle for clean).
  final String? badge;

  @override
  String get visualId => '$emoji|$scale|${effect.name}|$badge';
}

enum ShapeKind { circle, square, triangle, rectangle, star, heart, oval }

class ShapeVisual extends Visual {
  const ShapeVisual(this.shape, this.color);
  final ShapeKind shape;
  final Color color;
  @override
  String get visualId => 'shape:${shape.name}:${color.toARGB32()}';
}

class LetterVisual extends Visual {
  const LetterVisual(this.text, {this.color = const Color(0xFF3A2559)});
  final String text;
  final Color color;
  @override
  String get visualId => 'letter:$text';
}

class WordVisual extends Visual {
  const WordVisual(this.text, {this.emoji});
  final String text;

  /// Optional emoji shown above the word (e.g. speech bubble for "Moo").
  final String? emoji;
  @override
  String get visualId => 'word:$text';
}

class SwatchVisual extends Visual {
  const SwatchVisual(this.color, {this.label});
  final Color color;
  final String? label;
  @override
  String get visualId => 'swatch:${color.toARGB32()}';
}

enum SockPattern { plain, stripes, dots, stars, hearts }

class SockVisual extends Visual {
  const SockVisual(this.color, this.pattern);
  final Color color;
  final SockPattern pattern;
  @override
  String get visualId => 'sock:${color.toARGB32()}:${pattern.name}';
}

class QuantityVisual extends Visual {
  const QuantityVisual(this.emoji, this.count);
  final String emoji;
  final int count;
  @override
  String get visualId => 'qty:$emoji:$count';
}

/// A little illustrated scene: a gradient backdrop with a few emoji.
class SceneVisual extends Visual {
  const SceneVisual(this.id, this.emojis, this.top, this.bottom);
  final String id;
  final List<String> emojis;
  final Color top;
  final Color bottom;
  @override
  String get visualId => 'scene:$id';
}

/// A row of visuals ending in "?" - used by pattern completion prompts.
class SequenceVisual extends Visual {
  const SequenceVisual(this.items);
  final List<Visual> items;
  @override
  String get visualId => 'seq:${items.map((e) => e.visualId).join(',')}';
}

enum ClothingKind {
  tshirt,
  shirt,
  sweater,
  jacket,
  raincoat,
  shorts,
  trousers,
  jeans,
  leggings,
  skirt,
  towel,
  sock,
}

/// Hand-drawn clothing (custom painter) so colours can be coordinated into
/// outfit sets and gentle mud spots can be added for the laundry game.
class ClothingVisual extends Visual {
  const ClothingVisual(
    this.kind,
    this.color, {
    this.dirty = false,
    this.clean = false,
    this.pattern = SockPattern.plain,
  });

  final ClothingKind kind;
  final Color color;
  final bool dirty;

  /// Shows a little sparkle to make "clean" obvious.
  final bool clean;
  final SockPattern pattern;

  @override
  String get visualId =>
      'cloth:${kind.name}:${color.toARGB32()}:$dirty:${pattern.name}';
}

enum LiquidContainer { glass, bottle, cup }

/// A see-through container with a liquid inside: the liquid is the thing
/// being sorted, not the glass.
class LiquidVisual extends Visual {
  const LiquidVisual(this.color, {this.container = LiquidContainer.glass});
  final Color color;
  final LiquidContainer container;
  @override
  String get visualId => 'liquid:${color.toARGB32()}:${container.name}';
}
