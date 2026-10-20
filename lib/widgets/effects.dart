import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gently pulses its child (hints, highlighted targets). Static when
/// [active] is false or motion is reduced.
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    required this.active,
    this.reducedMotion = false,
    this.amount = 0.07,
  });

  final Widget child;
  final bool active;
  final bool reducedMotion;
  final double amount;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active && !widget.reducedMotion) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1 + widget.amount * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Plays a soft side-to-side wiggle whenever [trigger] changes.
/// Used for "not quite - try again" (never a harsh red flash).
class Wiggle extends StatefulWidget {
  const Wiggle({
    super.key,
    required this.child,
    required this.trigger,
    this.reducedMotion = false,
  });

  final Widget child;
  final int trigger;
  final bool reducedMotion;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(Wiggle old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !widget.reducedMotion) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = sin(t * pi * 4) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// A burst of sparkles/stars that plays when [trigger] changes.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({
    super.key,
    required this.trigger,
    this.reducedMotion = false,
    this.size = 140,
  });

  final int trigger;
  final bool reducedMotion;
  final double size;

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(SparkleBurst old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (!_c.isAnimating) return SizedBox.square(dimension: widget.size);
          final t = Curves.easeOut.transform(_c.value);
          final opacity = (1 - _c.value).clamp(0.0, 1.0);
          const emojis = ['✨', '⭐', '💖', '✨', '🌟', '⭐'];
          return SizedBox.square(
            dimension: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < emojis.length; i++)
                  Transform.translate(
                    offset: widget.reducedMotion
                        ? Offset.zero
                        : Offset.fromDirection(
                            i * 2 * pi / emojis.length - pi / 2,
                            widget.size * 0.42 * t,
                          ),
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        emojis[i],
                        style: TextStyle(fontSize: widget.size * 0.16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Falling confetti for celebration screens.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.enabled = true});
  final bool enabled;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _pieces = List.generate(40, (i) => i);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    if (widget.enabled) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    const colors = AppColors.cardPalette;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_c.value, _pieces, colors),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.pieces, this.colors);
  final double t;
  final List<int> pieces;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final rnd = Random(3);
    for (final i in pieces) {
      final x = rnd.nextDouble() * size.width;
      final delay = rnd.nextDouble() * 0.4;
      final speed = 0.7 + rnd.nextDouble() * 0.6;
      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0) * speed;
      if (p <= 0) continue;
      final y = -20 + p * (size.height + 40);
      final wobble = sin(p * 10 + i) * 18;
      canvas.save();
      canvas.translate(x + wobble, y);
      canvas.rotate(p * 8 + i);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 1 - t * 0.6);
      if (i.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, -3, 12, 6),
            const Radius.circular(3),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 4.5, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Friendly speech bubble used for hints ("Try the blue basket!").
class HintBubble extends StatelessWidget {
  const HintBubble({super.key, required this.text, this.emoji = '💡'});
  final String text;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: AppText.title(text.length > 28 ? 16 : 19),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
