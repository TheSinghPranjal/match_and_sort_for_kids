import 'dart:math';

import 'package:flutter/material.dart';

import '../models/visual.dart';
import '../theme/app_theme.dart';
import 'painters.dart';

/// Renders any [Visual] into a square of [size] logical pixels.
class ItemArt extends StatelessWidget {
  const ItemArt(this.visual, {super.key, required this.size});

  final Visual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = visual;
    final Widget child = switch (v) {
      EmojiVisual() => _emoji(v),
      ShapeVisual() => CustomPaint(painter: ShapePainter(v.shape, v.color)),
      LetterVisual() => Center(
        child: FittedBox(
          child: Padding(
            padding: EdgeInsets.all(size * 0.06),
            child: Text(
              v.text,
              style: AppText.display(size * 0.66, color: v.color).copyWith(
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    offset: const Offset(-1, -1),
                  ),
                  Shadow(
                    color: AppColors.darken(
                      v.color,
                      0.1,
                    ).withValues(alpha: 0.25),
                    offset: const Offset(2, 3),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      WordVisual() => Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.05),
          child: FittedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (v.emoji != null)
                  Text(v.emoji!, style: TextStyle(fontSize: size * 0.3)),
                Text(v.text, style: AppText.display(size * 0.34)),
              ],
            ),
          ),
        ),
      ),
      SwatchVisual() => Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: SwatchPainter(v.color),
              size: Size.infinite,
            ),
          ),
          if (v.label != null)
            Text(
              v.label!,
              style: AppText.title(size * 0.16),
              maxLines: 1,
              overflow: TextOverflow.fade,
            ),
        ],
      ),
      SockVisual() => CustomPaint(painter: SockPainter(v)),
      ClothingVisual() => CustomPaint(painter: ClothingPainter(v)),
      LiquidVisual() => CustomPaint(painter: LiquidPainter(v)),
      QuantityVisual() => _quantity(v),
      SceneVisual() => _scene(v),
      SequenceVisual() => _sequence(v),
    };
    return SizedBox(
      width: v is SequenceVisual ? null : size,
      height: size,
      child: child,
    );
  }

  Widget _emojiText(String e, double fontSize) => Text(
    e,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: fontSize, height: 1.15),
  );

  Widget _emoji(EmojiVisual v) {
    final fs = size * 0.66 * v.scale;
    Widget art = Center(child: _emojiText(v.emoji, fs));
    switch (v.effect) {
      case EmojiEffect.none:
        break;
      case EmojiEffect.silhouette:
        art = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0, 0, 0, 0, 58, //
            0, 0, 0, 0, 37,
            0, 0, 0, 0, 89,
            0, 0, 0, 1, 0,
          ]),
          child: art,
        );
      case EmojiEffect.leftHalf:
      case EmojiEffect.rightHalf:
        final left = v.effect == EmojiEffect.leftHalf;
        art = Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!left) _cutEdge(),
              ClipRect(
                child: Align(
                  alignment: left
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  widthFactor: 0.5,
                  child: _emojiText(v.emoji, fs * 1.2),
                ),
              ),
              if (left) _cutEdge(),
            ],
          ),
        );
      case EmojiEffect.mud:
        art = Stack(
          fit: StackFit.expand,
          children: [
            art,
            CustomPaint(painter: MudPainter()),
          ],
        );
      case EmojiEffect.steam:
        art = Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(top: size * 0.18),
              child: art,
            ),
            CustomPaint(painter: SteamPainter()),
          ],
        );
      case EmojiEffect.frost:
        break;
    }
    if (v.badge != null) {
      art = Stack(
        fit: StackFit.expand,
        children: [
          art,
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(v.badge!, style: TextStyle(fontSize: size * 0.22)),
          ),
        ],
      );
    }
    return art;
  }

  Widget _cutEdge() => Container(
    width: max(2, size * 0.025),
    height: size * 0.7,
    decoration: BoxDecoration(
      color: AppColors.inkSoft.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _quantity(QuantityVisual v) {
    final cols = v.count <= 3
        ? v.count
        : (v.count <= 4 ? 2 : (v.count <= 9 ? 3 : 4));
    final rows = (v.count / cols).ceil();
    final cell = size / max(cols, rows);
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < v.count; i++)
            SizedBox(
              width: cell * 0.95,
              height: cell * 0.95,
              child: Center(child: _emojiText(v.emoji, cell * 0.62)),
            ),
        ],
      ),
    );
  }

  Widget _scene(SceneVisual v) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [v.top, v.bottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -size * 0.2,
              right: -size * 0.2,
              bottom: -size * 0.32,
              height: size * 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size, size * 0.4),
                  ),
                ),
              ),
            ),
            if (v.emojis.isNotEmpty)
              Center(child: _emojiText(v.emojis.first, size * 0.46)),
            if (v.emojis.length > 1)
              Positioned(
                left: size * 0.06,
                top: size * 0.06,
                child: _emojiText(v.emojis[1], size * 0.22),
              ),
            if (v.emojis.length > 2)
              Positioned(
                right: size * 0.06,
                bottom: size * 0.06,
                child: _emojiText(v.emojis[2], size * 0.22),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sequence(SequenceVisual v) {
    final cell = size * 0.62;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in v.items)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cell * 0.04),
            child: ItemArt(item, size: cell),
          ),
        Container(
          width: cell,
          height: cell,
          margin: EdgeInsets.only(left: cell * 0.08),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lavenderDeep, width: 3),
          ),
          child: Center(
            child: Text(
              '?',
              style: AppText.display(cell * 0.6, color: AppColors.lavenderDeep),
            ),
          ),
        ),
      ],
    );
  }
}
