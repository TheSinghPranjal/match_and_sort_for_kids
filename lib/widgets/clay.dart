import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A puffy, inflated "clay" surface: a soft coloured drop shadow outside,
/// a light inner highlight at the top-left, a darker inner shade at the
/// bottom-right and a glossy sheen. Flutter has no inset box shadows, so the
/// inner layers are painted by [_ClayInnerPainter].
class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    required this.child,
    this.color = AppColors.cream,
    this.radius = 32,
    this.padding = const EdgeInsets.all(16),
    this.depth = 1.0,
    this.width,
    this.height,
    this.borderColor,
    this.borderWidth = 0,
    this.gradient,
  });

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// 0 = flat (pressed), 1 = normal, >1 = extra puffy.
  final double depth;
  final double? width;
  final double? height;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final shadow = AppColors.darken(color, 0.28);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null && borderWidth > 0
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: depth <= 0
            ? null
            : [
                BoxShadow(
                  color: shadow.withValues(alpha: 0.45),
                  offset: Offset(0, 10 * depth),
                  blurRadius: 22 * depth,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: shadow.withValues(alpha: 0.25),
                  offset: Offset(0, 3 * depth),
                  blurRadius: 4 * depth,
                ),
              ],
      ),
      child: CustomPaint(
        foregroundPainter: _ClayInnerPainter(
          color: color,
          radius: radius,
          depth: depth,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _ClayInnerPainter extends CustomPainter {
  _ClayInnerPainter({
    required this.color,
    required this.radius,
    required this.depth,
  });

  final Color color;
  final double radius;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final d = depth.clamp(0.0, 1.6);
    _inner(
      canvas,
      rrect,
      Colors.white.withValues(alpha: 0.65),
      Offset(6 * d + 1, 6 * d + 1),
      8,
    );
    _inner(
      canvas,
      rrect,
      AppColors.darken(color, 0.22).withValues(alpha: 0.55),
      Offset(-7 * d - 1, -8 * d - 1),
      10,
    );

    // Glossy sheen near the top-left corner.
    final sheenW = size.width * 0.45;
    final sheenH = (size.height * 0.22).clamp(6.0, 40.0);
    final sheen = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(radius * 0.45, 6, sheenW, sheenH),
        Radius.circular(sheenH),
      ),
      sheen,
    );
    canvas.restore();
  }

  void _inner(
    Canvas canvas,
    RRect rrect,
    Color c,
    Offset offset,
    double sigma,
  ) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rrect.outerRect.inflate(sigma * 3 + offset.distance))
      ..addRRect(rrect.shift(offset));
    canvas.drawPath(
      path,
      Paint()
        ..color = c
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
  }

  @override
  bool shouldRepaint(_ClayInnerPainter old) =>
      old.color != color || old.radius != radius || old.depth != depth;
}

/// Squishy pressable wrapper: shrinks and flattens on press.
class Squishy extends StatefulWidget {
  const Squishy({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool haptics;

  @override
  State<Squishy> createState() => _SquishyState();
}

class _SquishyState extends State<Squishy> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                if (widget.haptics) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.93 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Big chunky clay button with an optional icon.
class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = AppColors.coralDeep,
    this.textColor = Colors.white,
    this.height = 64,
    this.fontSize = 24,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final double height;
  final double fontSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: textColor, size: fontSize + 6),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            style: AppText.button(fontSize, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return Squishy(
      onTap: onTap,
      semanticLabel: label,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: ClayContainer(
          color: color,
          radius: height / 2,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// Round clay icon button (pause, home, speaker...). 60px by default.
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.color = AppColors.cream,
    this.iconColor = AppColors.ink,
    this.size = 60,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: ClayContainer(
        color: color,
        radius: size / 2,
        width: size,
        height: size,
        padding: EdgeInsets.zero,
        child: Center(
          child: Icon(icon, color: iconColor, size: size * 0.5),
        ),
      ),
    );
  }
}

/// Small pill showing a counter (stars, age group, timer).
class ClayPill extends StatelessWidget {
  const ClayPill({
    super.key,
    required this.emoji,
    required this.text,
    this.color = AppColors.cream,
  });

  final String emoji;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      color: color,
      radius: 24,
      depth: 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppText.title(20),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
