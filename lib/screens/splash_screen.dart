import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/garden_background.dart';
import 'home_screen.dart';

/// How long the splash stays up before the home screen.
const Duration kSplashDuration = Duration(milliseconds: 2000);

/// Studio mark shown only on the splash byline. Not the launcher icon.
const String kLazyBearClubAsset = 'assets/branding/lazy_bear_club.png';

const Key kLazyBearClubLogoKey = Key('lazy_bear_club_logo');

/// Same sky-and-hills world as the rest of the app. Emoji stickers are left
/// off so they don't crowd the byline sitting on the hill.
const GameTheme _dayGarden = GameTheme(
  top: Color(0xFF8ED6FF),
  bottom: Color(0xFFD6F1FF),
  ground: Color(0xFF8EDB6A),
);

/// Twilight garden used when the surrounding theme is dark, so the splash
/// stays in the same illustrated world without a bright sky behind dark UI.
const GameTheme _duskGarden = GameTheme(
  top: Color(0xFF2C2458),
  bottom: Color(0xFF3E4F8F),
  ground: Color(0xFF2E6A48),
);

/// First screen: the app name, then a short studio byline, then home.
///
/// The native launch background is the same sky colour, so the hand-off
/// from the OS splash does not flash white.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.duration = kSplashDuration});

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _enter,
    curve: Curves.easeOutCubic,
  );

  Timer? _hold;
  var _motionReady = false;
  var _reduceMotion = false;
  var _prefetched = false;

  @override
  void initState() {
    super.initState();
    _hold = Timer(widget.duration, _openHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (!_motionReady) {
      _motionReady = true;
      _reduceMotion = scope?.settings.reducedMotion ?? false;
      if (_reduceMotion) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    }
    if (!_prefetched) {
      _prefetched = true;
      precacheImage(const AssetImage(kLazyBearClubAsset), context);
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    _curve.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final garden = dark ? _duskGarden : _dayGarden;
    return Scaffold(
      backgroundColor: garden.top,
      body: GardenBackground(
        theme: garden,
        animate: !_reduceMotion,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortest = constraints.biggest.shortestSide;
              final roomy = shortest >= 600 && constraints.maxHeight >= 700;
              final compact = constraints.maxHeight < 480;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  roomy ? 32 : 20,
                  compact ? 4 : 8,
                  roomy ? 32 : 20,
                  compact ? 8 : 12,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _entrance(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _Hero(scale: roomy ? 1.3 : 1),
                          ),
                        ),
                      ),
                    ),
                    _entrance(
                      child: _StudioByline(compact: compact, roomy: roomy),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _entrance({required Widget child}) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_curve),
        child: child,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final mark = 128.0 * scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: ClayContainer(
            color: AppColors.peach,
            radius: 46 * scale,
            width: mark,
            height: mark,
            padding: EdgeInsets.all(8 * scale),
            child: const CustomPaint(
              painter: _BearMarkPainter(),
              child: SizedBox.expand(),
            ),
          ),
        ),
        SizedBox(height: 18 * scale),
        _RainbowTitle('Match & Sort', size: 54 * scale),
      ],
    );
  }
}

/// Same sticker-outline rainbow wordmark as the home header, centered.
class _RainbowTitle extends StatelessWidget {
  const _RainbowTitle(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.coralDeep,
      AppColors.sunnyDeep,
      AppColors.mintDeep,
      AppColors.skyDeep,
      AppColors.lavenderDeep,
      Color(0xFFFF5FA8),
    ];
    final base = AppText.display(size);
    final stroke = (size * 0.2).clamp(6.0, 14.0);
    var ci = 0;
    final fill = <TextSpan>[
      for (final ch in text.characters)
        TextSpan(
          text: ch,
          style: base.copyWith(
            color: ch.trim().isEmpty ? null : colors[ci++ % colors.length],
          ),
        ),
    ];
    final outline = <TextSpan>[
      for (final ch in text.characters)
        TextSpan(
          text: ch,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
          ),
        ),
    ];
    return Semantics(
      header: true,
      label: text,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text.rich(TextSpan(children: outline)),
              Text.rich(TextSpan(children: fill)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A painted bear face, so the splash mascot matches the clay garden
/// without depending on an emoji font.
class _BearMarkPainter extends CustomPainter {
  const _BearMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2 + s * 0.02);
    final ear = Paint()..color = const Color(0xFFE9895A);
    final innerEar = Paint()..color = const Color(0xFFFFC2A8);
    final head = Paint()..color = const Color(0xFFFFB184);
    final snout = Paint()..color = AppColors.cream;
    final ink = Paint()..color = AppColors.ink;

    canvas.drawCircle(c + Offset(-s * 0.28, -s * 0.28), s * 0.16, ear);
    canvas.drawCircle(c + Offset(s * 0.28, -s * 0.28), s * 0.16, ear);
    canvas.drawCircle(c + Offset(-s * 0.28, -s * 0.28), s * 0.075, innerEar);
    canvas.drawCircle(c + Offset(s * 0.28, -s * 0.28), s * 0.075, innerEar);
    canvas.drawCircle(c, s * 0.36, head);
    canvas.drawCircle(
      c + Offset(-s * 0.16, s * 0.06),
      s * 0.045,
      Paint()..color = const Color(0xFFFF8A7A),
    );
    canvas.drawCircle(
      c + Offset(s * 0.16, s * 0.06),
      s * 0.045,
      Paint()..color = const Color(0xFFFF8A7A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, s * 0.12),
        width: s * 0.28,
        height: s * 0.22,
      ),
      snout,
    );
    canvas.drawCircle(c + Offset(0, s * 0.08), s * 0.042, ink);
    canvas.drawCircle(c + Offset(-s * 0.12, -s * 0.05), s * 0.032, ink);
    canvas.drawCircle(c + Offset(s * 0.12, -s * 0.05), s * 0.032, ink);
    canvas.drawCircle(
      c + Offset(-s * 0.108, -s * 0.062),
      s * 0.011,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      c + Offset(s * 0.132, -s * 0.062),
      s * 0.011,
      Paint()..color = Colors.white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 0.07, c.dy + s * 0.16)
        ..quadraticBezierTo(
          c.dx,
          c.dy + s * 0.24,
          c.dx + s * 0.07,
          c.dy + s * 0.16,
        ),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BearMarkPainter oldDelegate) => false;
}

class _StudioByline extends StatelessWidget {
  const _StudioByline({required this.compact, required this.roomy});

  final bool compact;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final icon = roomy ? 80.0 : (compact ? 48.0 : 64.0);
    final nameSize = roomy ? 26.0 : (compact ? 18.0 : 22.0);
    final bySize = roomy ? 18.0 : (compact ? 14.0 : 16.0);
    final radius = icon * 0.22;
    // Cream card in both themes: ink on cream stays high-contrast whether
    // the garden behind it is the daytime sky or the dusk theme.
    return Semantics(
      label: 'by The Lazy Bear Club',
      child: ExcludeSemantics(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ClayContainer(
              color: AppColors.cream,
              radius: compact ? 24 : 30,
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 18,
                compact ? 10 : 14,
                compact ? 14 : 18,
                compact ? 12 : 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: AppColors.peach, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        math.max(0, radius - 2),
                      ),
                      child: Image.asset(
                        kLazyBearClubAsset,
                        key: kLazyBearClubLogoKey,
                        width: icon,
                        height: icon,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text('by', style: AppText.body(bySize, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'The Lazy Bear Club',
                      maxLines: 1,
                      style: AppText.title(nameSize, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
