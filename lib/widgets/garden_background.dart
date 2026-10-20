import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_models.dart';

/// The sky-and-hills garden world every screen lives in: gradient sky,
/// a smiling sun, puffy clouds, two rolling hills and tiny flowers.
/// Decorations sit behind content and ignore touches, so they can never
/// cover an answer.
class GardenBackground extends StatefulWidget {
  const GardenBackground({
    super.key,
    required this.theme,
    required this.child,
    this.animate = true,
    this.showSun = true,
  });

  final GameTheme theme;
  final Widget child;
  final bool animate;
  final bool showSun;

  @override
  State<GardenBackground> createState() => _GardenBackgroundState();
}

class _GardenBackgroundState extends State<GardenBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _drift.repeat();
  }

  @override
  void didUpdateWidget(GardenBackground old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_drift.isAnimating) {
      _drift.repeat();
    } else if (!widget.animate && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return ColoredBox(
      color: t.bottom,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (context, _) => CustomPaint(
                  painter: _GardenPainter(t, _drift.value, widget.showSun),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: LayoutBuilder(
              builder: (context, c) {
                final deco = t.decorations;
                if (deco.isEmpty) return const SizedBox.shrink();
                final fs = min(c.maxWidth, c.maxHeight) * 0.07;
                return Stack(
                  children: [
                    for (var i = 0; i < deco.length; i++)
                      Positioned(
                        left: i.isEven
                            ? c.maxWidth * (0.02 + 0.1 * (i ~/ 2))
                            : null,
                        right: i.isOdd
                            ? c.maxWidth * (0.02 + 0.1 * (i ~/ 2))
                            : null,
                        bottom: c.maxHeight * (0.015 + 0.03 * (i % 3)),
                        child: Opacity(
                          opacity: 0.85,
                          child: Text(deco[i], style: TextStyle(fontSize: fs)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GardenPainter extends CustomPainter {
  _GardenPainter(this.t, this.drift, this.showSun);
  final GameTheme t;
  final double drift;
  final bool showSun;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.top, t.bottom],
        ).createShader(Offset.zero & size),
    );

    if (showSun) {
      final sunC = Offset(w * 0.86, h * 0.09);
      final r = min(w, h) * 0.07;
      canvas.drawCircle(
        sunC,
        r * 1.6,
        Paint()..color = const Color(0x55FFE58A),
      );
      canvas.drawCircle(sunC, r, Paint()..color = const Color(0xFFFFD84D));
      canvas.drawCircle(
        sunC.translate(-r * 0.3, -r * 0.3),
        r * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }

    // Puffy clouds drifting slowly.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final (y, s, speed, phase) in const [
      (0.08, 1.0, 1.0, 0.1),
      (0.18, 0.7, 0.6, 0.55),
      (0.28, 0.55, 0.8, 0.85),
    ]) {
      final x = ((phase + drift * speed) % 1.3 - 0.15) * w;
      final cw = min(w, 600.0) * 0.22 * s;
      final cy = h * y;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, cy), width: cw, height: cw * 0.32),
          Radius.circular(cw),
        ),
        cloud,
      );
      canvas.drawCircle(Offset(x - cw * 0.15, cy - cw * 0.12), cw * 0.2, cloud);
      canvas.drawCircle(
        Offset(x + cw * 0.12, cy - cw * 0.16),
        cw * 0.25,
        cloud,
      );
    }

    // Rolling hills.
    final back = Paint()..color = Color.lerp(t.ground, Colors.white, 0.35)!;
    final front = Paint()..color = t.ground;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.86)
        ..quadraticBezierTo(w * 0.25, h * 0.78, w * 0.55, h * 0.85)
        ..quadraticBezierTo(w * 0.8, h * 0.91, w, h * 0.82)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      back,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.92)
        ..quadraticBezierTo(w * 0.35, h * 0.86, w * 0.7, h * 0.93)
        ..quadraticBezierTo(w * 0.88, h * 0.96, w, h * 0.91)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      front,
    );

    // Tiny flowers on the front hill.
    final rnd = Random(7);
    const petals = [
      Color(0xFFFF8FB8),
      Color(0xFFFFE066),
      Color(0xFFFFFFFF),
      Color(0xFFB49CFF),
    ];
    for (var i = 0; i < 14; i++) {
      final fx = rnd.nextDouble() * w;
      final fy = h * (0.95 + rnd.nextDouble() * 0.04);
      final pr = 3.0 + rnd.nextDouble() * 2;
      final p = Paint()..color = petals[i % petals.length];
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * pi / 5;
        canvas.drawCircle(
          Offset(fx + cos(a) * pr, fy + sin(a) * pr),
          pr * 0.8,
          p,
        );
      }
      canvas.drawCircle(
        Offset(fx, fy),
        pr * 0.6,
        Paint()..color = const Color(0xFFFFB627),
      );
    }
  }

  @override
  bool shouldRepaint(_GardenPainter old) =>
      old.drift != drift || old.t != t || old.showSun != showSun;
}
