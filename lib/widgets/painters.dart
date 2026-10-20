import 'dart:math';

import 'package:flutter/material.dart';

import '../models/visual.dart';
import '../theme/app_theme.dart';

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// Draws a filled shape with a chunky outline and a clay-style gloss.
class ShapePainter extends CustomPainter {
  ShapePainter(this.shape, this.color);
  final ShapeKind shape;
  final Color color;

  static Path pathFor(ShapeKind shape, Rect r) {
    final c = r.center;
    final w = r.width, h = r.height;
    switch (shape) {
      case ShapeKind.circle:
        return Path()..addOval(Rect.fromCircle(center: c, radius: w * 0.42));
      case ShapeKind.square:
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: w * 0.78, height: w * 0.78),
            Radius.circular(w * 0.1),
          ),
        );
      case ShapeKind.rectangle:
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: w * 0.9, height: h * 0.5),
            Radius.circular(w * 0.08),
          ),
        );
      case ShapeKind.oval:
        return Path()..addOval(
          Rect.fromCenter(center: c, width: w * 0.62, height: h * 0.86),
        );
      case ShapeKind.triangle:
        return Path()
          ..moveTo(c.dx, r.top + h * 0.1)
          ..lineTo(r.left + w * 0.06, r.top + h * 0.86)
          ..lineTo(r.right - w * 0.06, r.top + h * 0.86)
          ..close();
      case ShapeKind.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final rad = i.isEven ? w * 0.46 : w * 0.2;
          final a = -pi / 2 + i * pi / 5;
          final p = Offset(c.dx + rad * cos(a), c.dy + 0.04 * h + rad * sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
      case ShapeKind.heart:
        final x = r.left, y = r.top;
        return Path()
          ..moveTo(x + w * 0.5, y + h * 0.88)
          ..cubicTo(
            x + w * 0.05,
            y + h * 0.6,
            x + w * 0.0,
            y + h * 0.3,
            x + w * 0.22,
            y + h * 0.16,
          )
          ..cubicTo(
            x + w * 0.38,
            y + h * 0.06,
            x + w * 0.5,
            y + h * 0.18,
            x + w * 0.5,
            y + h * 0.28,
          )
          ..cubicTo(
            x + w * 0.5,
            y + h * 0.18,
            x + w * 0.62,
            y + h * 0.06,
            x + w * 0.78,
            y + h * 0.16,
          )
          ..cubicTo(
            x + w * 1.0,
            y + h * 0.3,
            x + w * 0.95,
            y + h * 0.6,
            x + w * 0.5,
            y + h * 0.88,
          )
          ..close();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = pathFor(shape, Offset.zero & size);
    final isWhite = color.computeLuminance() > 0.9;
    canvas.drawShadow(path, AppColors.darken(color, 0.4), 4, false);
    canvas.drawPath(path, _fill(color));
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.28),
      size.width * 0.22,
      _fill(Colors.white.withValues(alpha: isWhite ? 0 : 0.28)),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      _stroke(
        isWhite ? AppColors.ink : AppColors.darken(color, 0.22),
        size.width * 0.045,
      ),
    );
  }

  @override
  bool shouldRepaint(ShapePainter old) =>
      old.shape != shape || old.color != color;
}

/// Clothing illustrations drawn on a 100x100 grid.
class ClothingPainter extends CustomPainter {
  ClothingPainter(this.v);
  final ClothingVisual v;

  Path _path(ClothingKind k) {
    Path poly(List<double> pts) {
      final p = Path()..moveTo(pts[0], pts[1]);
      for (var i = 2; i < pts.length; i += 2) {
        p.lineTo(pts[i], pts[i + 1]);
      }
      return p..close();
    }

    switch (k) {
      case ClothingKind.tshirt:
      case ClothingKind.shirt:
        return Path()
          ..moveTo(32, 12)
          ..lineTo(41, 12)
          ..quadraticBezierTo(50, 22, 59, 12)
          ..lineTo(68, 12)
          ..lineTo(92, 30)
          ..lineTo(82, 44)
          ..lineTo(72, 38)
          ..lineTo(72, 90)
          ..lineTo(28, 90)
          ..lineTo(28, 38)
          ..lineTo(18, 44)
          ..lineTo(8, 30)
          ..close();
      case ClothingKind.sweater:
      case ClothingKind.jacket:
      case ClothingKind.raincoat:
        return Path()
          ..moveTo(32, 12)
          ..lineTo(41, 12)
          ..quadraticBezierTo(50, 20, 59, 12)
          ..lineTo(68, 12)
          ..lineTo(88, 24)
          ..lineTo(96, 80)
          ..lineTo(84, 82)
          ..lineTo(74, 42)
          ..lineTo(74, 92)
          ..lineTo(26, 92)
          ..lineTo(26, 42)
          ..lineTo(16, 82)
          ..lineTo(4, 80)
          ..lineTo(12, 24)
          ..close();
      case ClothingKind.shorts:
        return poly([22, 18, 78, 18, 86, 74, 56, 74, 50, 44, 44, 74, 14, 74]);
      case ClothingKind.trousers:
      case ClothingKind.jeans:
        return poly([26, 8, 74, 8, 80, 94, 58, 94, 50, 36, 42, 94, 20, 94]);
      case ClothingKind.leggings:
        return poly([32, 8, 68, 8, 66, 94, 54, 94, 50, 36, 46, 94, 34, 94]);
      case ClothingKind.skirt:
        return Path()
          ..moveTo(32, 18)
          ..lineTo(68, 18)
          ..lineTo(88, 80)
          ..quadraticBezierTo(50, 92, 12, 80)
          ..close();
      case ClothingKind.towel:
        return Path()
          ..addRRect(RRect.fromLTRBR(18, 10, 82, 90, const Radius.circular(8)));
      case ClothingKind.sock:
        return SockPainter.sockPath(const Size(100, 100));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);
    final path = _path(v.kind);
    final outline = AppColors.darken(v.color, 0.25);
    canvas.drawShadow(path, AppColors.darken(v.color, 0.45), 3, false);
    canvas.drawPath(path, _fill(v.color));

    canvas.save();
    canvas.clipPath(path);
    _details(canvas, outline);
    _pattern(canvas);
    canvas.drawCircle(
      const Offset(36, 34),
      14,
      _fill(Colors.white.withValues(alpha: 0.22)),
    );
    if (v.dirty) _mud(canvas);
    canvas.restore();

    canvas.drawPath(path, _stroke(outline, 3.2));
    if (v.kind == ClothingKind.raincoat) {
      // Hood.
      canvas.drawArc(
        const Rect.fromLTWH(34, 0, 32, 26),
        pi,
        pi,
        false,
        _stroke(outline, 3.2)..strokeWidth = 5,
      );
    }
    canvas.restore();
    if (v.clean) _sparkles(canvas, size);
  }

  void _details(Canvas canvas, Color outline) {
    final line = _stroke(outline.withValues(alpha: 0.7), 2.4);
    switch (v.kind) {
      case ClothingKind.shirt:
        canvas.drawPath(
          Path()
            ..moveTo(41, 12)
            ..lineTo(46, 26)
            ..lineTo(50, 18)
            ..lineTo(54, 26)
            ..lineTo(59, 12),
          _fill(Colors.white.withValues(alpha: 0.85)),
        );
        for (var y = 32.0; y < 86; y += 12) {
          canvas.drawCircle(Offset(50, y), 2.2, _fill(outline));
        }
      case ClothingKind.sweater:
        for (var x = 30.0; x < 72; x += 6) {
          canvas.drawLine(Offset(x, 84), Offset(x, 92), line);
        }
        canvas.drawLine(const Offset(5, 74), const Offset(16, 76), line);
        canvas.drawLine(const Offset(84, 76), const Offset(95, 74), line);
      case ClothingKind.jacket:
      case ClothingKind.raincoat:
        canvas.drawLine(const Offset(50, 16), const Offset(50, 92), line);
        canvas.drawRRect(
          RRect.fromLTRBR(32, 62, 44, 74, const Radius.circular(2)),
          line,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(56, 62, 68, 74, const Radius.circular(2)),
          line,
        );
      case ClothingKind.jeans:
        canvas.drawLine(const Offset(30, 16), const Offset(70, 16), line);
        canvas.drawLine(const Offset(30, 22), const Offset(38, 30), line);
        canvas.drawLine(const Offset(70, 22), const Offset(62, 30), line);
      case ClothingKind.trousers:
      case ClothingKind.leggings:
      case ClothingKind.shorts:
      case ClothingKind.skirt:
        canvas.drawRect(
          const Rect.fromLTRB(0, 8, 100, 24),
          _fill(Colors.black.withValues(alpha: 0.10)),
        );
      case ClothingKind.towel:
        canvas.drawRect(
          const Rect.fromLTRB(0, 22, 100, 30),
          _fill(Colors.white.withValues(alpha: 0.7)),
        );
        canvas.drawRect(
          const Rect.fromLTRB(0, 70, 100, 78),
          _fill(Colors.white.withValues(alpha: 0.7)),
        );
      case ClothingKind.tshirt:
      case ClothingKind.sock:
        break;
    }
  }

  void _pattern(Canvas canvas) {
    final p = _fill(Colors.white.withValues(alpha: 0.75));
    switch (v.pattern) {
      case SockPattern.plain:
        break;
      case SockPattern.stripes:
        for (var y = 30.0; y < 96; y += 16) {
          canvas.drawRect(Rect.fromLTRB(0, y, 100, y + 6), p);
        }
      case SockPattern.dots:
        for (var y = 30.0; y < 96; y += 16) {
          for (var x = 20.0 + (y % 32 == 30 ? 0 : 8); x < 90; x += 16) {
            canvas.drawCircle(Offset(x, y), 3.6, p);
          }
        }
      case SockPattern.stars:
      case SockPattern.hearts:
        final kind = v.pattern == SockPattern.stars
            ? ShapeKind.star
            : ShapeKind.heart;
        for (final o in const [
          Offset(38, 46),
          Offset(60, 64),
          Offset(42, 78),
        ]) {
          canvas.drawPath(
            ShapePainter.pathFor(
              kind,
              Rect.fromCenter(center: o, width: 14, height: 14),
            ),
            p,
          );
        }
    }
  }

  void _mud(Canvas canvas) {
    final mud = _fill(const Color(0xFF8B5A2B).withValues(alpha: 0.75))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    for (final (o, r) in const [
      (Offset(40, 58), 7.0),
      (Offset(48, 64), 4.5),
      (Offset(62, 74), 6.0),
      (Offset(34, 80), 3.5),
      (Offset(66, 44), 3.0),
    ]) {
      canvas.drawCircle(o, r, mud);
    }
    canvas.drawPath(
      Path()
        ..moveTo(56, 30)
        ..quadraticBezierTo(62, 36, 58, 44),
      _stroke(const Color(0xFF4FAF3C), 3),
    );
  }

  void _sparkles(Canvas canvas, Size size) {
    final p = _fill(Colors.white);
    final o = _stroke(AppColors.sunnyDeep, size.width * 0.012);
    for (final (dx, dy, r) in const [(0.86, 0.12, 0.09), (0.12, 0.86, 0.06)]) {
      final path = ShapePainter.pathFor(
        ShapeKind.star,
        Rect.fromCenter(
          center: Offset(size.width * dx, size.height * dy),
          width: size.width * r * 2,
          height: size.width * r * 2,
        ),
      );
      canvas.drawPath(path, p);
      canvas.drawPath(path, o);
    }
  }

  @override
  bool shouldRepaint(ClothingPainter old) => old.v.visualId != v.visualId;
}

class SockPainter extends CustomPainter {
  SockPainter(this.v);
  final SockVisual v;

  static Path sockPath(Size s) {
    final w = s.width / 100, h = s.height / 100;
    return Path()
      ..moveTo(34 * w, 6 * h)
      ..lineTo(66 * w, 6 * h)
      ..lineTo(66 * w, 58 * h)
      ..quadraticBezierTo(66 * w, 66 * h, 74 * w, 70 * h)
      ..lineTo(84 * w, 76 * h)
      ..quadraticBezierTo(94 * w, 84 * h, 86 * w, 92 * h)
      ..quadraticBezierTo(80 * w, 98 * h, 68 * w, 94 * h)
      ..lineTo(42 * w, 82 * h)
      ..quadraticBezierTo(34 * w, 78 * h, 34 * w, 68 * h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    ClothingPainter(
      ClothingVisual(ClothingKind.sock, v.color, pattern: v.pattern),
    ).paint(canvas, size);
    // Cuff.
    final s = size.width / 100;
    canvas.drawRRect(
      RRect.fromLTRBR(33 * s, 5 * s, 67 * s, 16 * s, Radius.circular(3 * s)),
      _fill(Colors.white.withValues(alpha: 0.55)),
    );
  }

  @override
  bool shouldRepaint(SockPainter old) => old.v.visualId != v.visualId;
}

/// A see-through glass, cup or bottle with coloured liquid inside.
class LiquidPainter extends CustomPainter {
  LiquidPainter(this.v);
  final LiquidVisual v;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);
    final Path vessel;
    final double liquidTop;
    switch (v.container) {
      case LiquidContainer.glass:
        vessel = Path()
          ..moveTo(24, 10)
          ..lineTo(76, 10)
          ..lineTo(68, 92)
          ..lineTo(32, 92)
          ..close();
        liquidTop = 34;
      case LiquidContainer.cup:
        vessel = Path()
          ..moveTo(22, 20)
          ..lineTo(78, 20)
          ..lineTo(72, 92)
          ..lineTo(28, 92)
          ..close();
        liquidTop = 38;
      case LiquidContainer.bottle:
        vessel = Path()
          ..moveTo(42, 6)
          ..lineTo(58, 6)
          ..lineTo(58, 22)
          ..quadraticBezierTo(72, 28, 72, 42)
          ..lineTo(72, 88)
          ..quadraticBezierTo(72, 94, 66, 94)
          ..lineTo(34, 94)
          ..quadraticBezierTo(28, 94, 28, 88)
          ..lineTo(28, 42)
          ..quadraticBezierTo(28, 28, 42, 22)
          ..close();
        liquidTop = 44;
    }
    canvas.drawPath(vessel, _fill(Colors.white.withValues(alpha: 0.45)));
    canvas.save();
    canvas.clipPath(vessel);
    final liquid = Path()
      ..moveTo(0, liquidTop)
      ..quadraticBezierTo(25, liquidTop - 4, 50, liquidTop)
      ..quadraticBezierTo(75, liquidTop + 4, 100, liquidTop)
      ..lineTo(100, 100)
      ..lineTo(0, 100)
      ..close();
    canvas.drawPath(liquid, _fill(v.color));
    canvas.drawPath(
      liquid,
      _stroke(AppColors.darken(v.color, 0.12).withValues(alpha: 0.6), 2),
    );
    canvas.drawRect(
      Rect.fromLTWH(32, liquidTop + 8, 6, 40),
      _fill(Colors.white.withValues(alpha: 0.5)),
    );
    canvas.restore();
    canvas.drawPath(vessel, _stroke(const Color(0xFF7AA7C7), 3));
    if (v.container == LiquidContainer.cup) {
      // Straw.
      canvas.drawLine(
        const Offset(58, 26),
        const Offset(70, 2),
        _stroke(AppColors.coralDeep, 5),
      );
    }
    if (v.container == LiquidContainer.bottle) {
      canvas.drawRRect(
        RRect.fromLTRBR(40, 0, 60, 9, const Radius.circular(3)),
        _fill(AppColors.skyDeep),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LiquidPainter old) => old.v.visualId != v.visualId;
}

/// Paint-splat colour swatch.
class SwatchPainter extends CustomPainter {
  SwatchPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.38;
    final path = Path();
    for (var i = 0; i <= 24; i++) {
      final a = i / 24 * 2 * pi;
      final wobble = 1 + 0.08 * sin(a * 5);
      final p = Offset(c.dx + r * wobble * cos(a), c.dy + r * wobble * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawShadow(path, AppColors.darken(color, 0.4), 4, false);
    canvas.drawPath(path, _fill(color));
    canvas.drawCircle(
      c.translate(-r * 0.35, -r * 0.35),
      r * 0.25,
      _fill(Colors.white.withValues(alpha: 0.35)),
    );
    canvas.drawPath(
      path,
      _stroke(AppColors.darken(color, 0.2), size.width * 0.03),
    );
  }

  @override
  bool shouldRepaint(SwatchPainter old) => old.color != color;
}

/// Little wavy steam lines above hot food.
class SteamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = _stroke(Colors.white.withValues(alpha: 0.95), size.width * 0.035);
    final shadow = _stroke(const Color(0xFFB0B8C8), size.width * 0.05);
    for (final x in [0.36, 0.5, 0.64]) {
      final path = Path()..moveTo(size.width * x, size.height * 0.3);
      path.cubicTo(
        size.width * (x - 0.06),
        size.height * 0.22,
        size.width * (x + 0.06),
        size.height * 0.14,
        size.width * x,
        size.height * 0.04,
      );
      canvas.drawPath(path, shadow);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(SteamPainter old) => false;
}

/// Gentle mud spots over an emoji.
class MudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mud = _fill(const Color(0xFF8B5A2B).withValues(alpha: 0.7));
    for (final (dx, dy, r) in const [
      (0.42, 0.58, 0.07),
      (0.56, 0.66, 0.05),
      (0.62, 0.48, 0.04),
    ]) {
      canvas.drawCircle(
        Offset(size.width * dx, size.height * dy),
        size.width * r,
        mud,
      );
    }
  }

  @override
  bool shouldRepaint(MudPainter old) => false;
}
