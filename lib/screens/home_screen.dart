import 'dart:math';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/themes.dart';
import '../models/game_models.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/garden_background.dart';
import 'game_router.dart';
import 'parent_gate.dart';
import 'parent_zone_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameKind _mode = GameKind.sort;

  Future<void> _openParentZone() async {
    if (!await showParentGate(context) || !mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ParentZoneScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([app.settings, app.rewards]),
        builder: (context, _) {
          final s = app.settings;
          final limit = app.rewards.dailyLimitReached(s);
          return GardenBackground(
            theme: Themes.garden,
            animate: !s.reducedMotion,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _header(app)),
                      SliverToBoxAdapter(child: _modeTabs()),
                      ..._sections(app),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                  if (limit) _restOverlay(app),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(AppScope app) {
    final s = app.settings;
    final r = app.rewards;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              ClayContainer(
                color: AppColors.peach,
                radius: 34,
                width: 68,
                height: 68,
                padding: EdgeInsets.zero,
                child: const Center(
                  child: Text('🐻', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: _RainbowTitle('Match & Sort')),
              ClayIconButton(
                icon: Icons.lock_rounded,
                semanticLabel: 'Parent Zone',
                size: 52,
                color: Colors.white,
                iconColor: AppColors.inkSoft,
                onTap: _openParentZone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              // Age world as plain text, so the stars are the only
              // reward-looking pill on screen.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${s.ageGroup.title} · ages ${s.ageGroup.ages}',
                  style: AppText.title(18, color: AppColors.inkSoft),
                ),
              ),
              if (s.rewardsVisible) ...[
                ClayPill(
                  emoji: '⭐',
                  text: '${r.stars}',
                  color: AppColors.sunny,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeTabs() {
    Widget tab(GameKind kind, String emoji, String label, Color color) {
      final on = _mode == kind;
      return Expanded(
        child: Squishy(
          semanticLabel: '$label games',
          onTap: () => setState(() => _mode = kind),
          child: AnimatedScale(
            scale: on ? 1 : 0.94,
            duration: const Duration(milliseconds: 200),
            child: ClayContainer(
              color: on ? color : Colors.white,
              radius: 30,
              height: 72,
              depth: on ? 1.2 : 0.5,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.display(
                        26,
                        color: on ? Colors.white : AppColors.inkSoft,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          tab(GameKind.sort, '🧺', 'Sort', AppColors.coralDeep),
          const SizedBox(width: 14),
          tab(GameKind.match, '🧩', 'Match', AppColors.lavenderDeep),
        ],
      ),
    );
  }

  List<Widget> _sections(AppScope app) {
    final games = allGames
        .where((g) => g.kind == _mode && app.settings.isGameEnabled(g.id))
        .toList();
    if (games.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No games switched on here. Ask a grown-up! 🔒',
              style: AppText.title(20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }
    final out = <Widget>[];
    for (final section in GameSection.values) {
      final list = games.where((g) => g.section == section).toList();
      if (list.isEmpty) continue;
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Text(section.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    section.title,
                    style: AppText.display(22).copyWith(
                      shadows: [
                        const Shadow(color: Colors.white, blurRadius: 8),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      out.add(
        SliverToBoxAdapter(
          child: SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (context, i) => FunkyGameCard(
                game: list[i],
                rounds: app.rewards.progress[list[i].id]?.rounds ?? 0,
                onTap: () => launchGame(context, list[i]),
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  Widget _restOverlay(AppScope app) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.ink.withValues(alpha: 0.5),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClayContainer(
              color: AppColors.lavender,
              radius: 40,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😴', style: TextStyle(fontSize: 72)),
                  Text(
                    'Time for a rest!',
                    style: AppText.display(30),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You played so well today.\nSee you tomorrow!',
                    style: AppText.body(18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ClayButton(
                    label: 'Grown-up: 15 more min',
                    color: AppColors.lavenderDeep,
                    fontSize: 18,
                    height: 56,
                    onTap: () async {
                      if (await showParentGate(context)) {
                        app.rewards.grantExtraTime(15);
                      }
                    },
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

/// Bubbly multicolour logo text with a white sticker outline.
class _RainbowTitle extends StatelessWidget {
  const _RainbowTitle(this.text);
  final String text;

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
    var ci = 0;
    final base = AppText.display(34);
    final spans = [
      for (final ch in text.characters)
        TextSpan(
          text: ch,
          style: base.copyWith(
            color: ch.trim().isEmpty ? null : colors[ci++ % colors.length],
          ),
        ),
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Stack(
        children: [
          Text.rich(
            TextSpan(
              children: [
                for (final ch in text.characters)
                  TextSpan(
                    text: ch,
                    style: base.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 8
                        ..strokeJoin = StrokeJoin.round
                        ..color = Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          Text.rich(TextSpan(children: spans), semanticsLabel: text),
        ],
      ),
    );
  }
}

/// A chunky, tilted clay game card with polka dots and a sticker-style
/// cover illustration. Recognisable without reading the title.
class FunkyGameCard extends StatelessWidget {
  const FunkyGameCard({
    super.key,
    required this.game,
    required this.rounds,
    required this.onTap,
  });

  final GameDef game;
  final int rounds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.cardPalette[game.number % AppColors.cardPalette.length];
    final tilt = (game.number.isEven ? 1 : -1) * 0.025;
    final stars = min(3, rounds);
    return Squishy(
      onTap: onTap,
      semanticLabel: game.title,
      child: Transform.rotate(
        angle: tilt,
        child: SizedBox(
          width: 168,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClayContainer(
                color: color,
                radius: 34,
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: CustomPaint(
                    painter: _DotsPainter(AppColors.lighten(color, 0.12)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darken(
                                    color,
                                    0.3,
                                  ).withValues(alpha: 0.4),
                                  offset: const Offset(0, 6),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                game.cover,
                                style: const TextStyle(fontSize: 56),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 44,
                            child: Center(
                              child: Text(
                                game.title,
                                style: AppText.title(17),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 3; i++)
                                Opacity(
                                  opacity: i < stars ? 1 : 0.3,
                                  child: const Text(
                                    '⭐',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (rounds == 0)
                Positioned(
                  top: -8,
                  right: -6,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coralDeep,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Text('NEW', style: AppText.button(14)),
                    ),
                  ),
                ),
              if (game.minAge > 3)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${game.minAge}+', style: AppText.title(13)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var y = 10.0; y < size.height; y += 26) {
      final offset = (y ~/ 26).isEven ? 0.0 : 13.0;
      for (var x = 8.0 + offset; x < size.width; x += 26) {
        canvas.drawCircle(Offset(x, y), 4, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
