import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/match_engine.dart';
import '../models/game_models.dart';
import '../models/visual.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/garden_background.dart';
import '../widgets/item_art.dart';
import 'game_router.dart';

/// Short "how to play" screen: a picture demo, one sentence and a big Play
/// button. Shown before a game's first round.
class GameIntroScreen extends StatefulWidget {
  const GameIntroScreen({super.key, required this.game});
  final GameDef game;

  @override
  State<GameIntroScreen> createState() => _GameIntroScreenState();
}

class _GameIntroScreenState extends State<GameIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final app = AppScope.of(context);
    if (app.settings.reducedMotion) {
      _demo.value = 0.75;
    } else {
      _demo.repeat();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) app.audio.speak(widget.game.instruction);
    });
  }

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  void _play() {
    final app = AppScope.of(context);
    app.settings.markIntroSeen(widget.game.id);
    app.audio.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => gameScreenFor(widget.game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final g = widget.game;
    return Scaffold(
      body: GardenBackground(
        theme: g.theme,
        animate: !app.settings.reducedMotion,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClayIconButton(
                            icon: Icons.arrow_back_rounded,
                            semanticLabel: 'Back',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          ClayIconButton(
                            icon: Icons.volume_up_rounded,
                            semanticLabel: 'Hear instructions',
                            color: AppColors.sky,
                            onTap: () => app.audio.speak(g.instruction),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClayContainer(
                        color: AppColors.cream,
                        radius: 40,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                        child: Column(
                          children: [
                            Text(g.cover, style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 6),
                            Text(
                              g.title,
                              style: AppText.display(30),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              g.instruction,
                              style: AppText.body(19, color: AppColors.inkSoft),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: min(260, c.maxHeight * 0.36),
                        child: AnimatedBuilder(
                          animation: _demo,
                          builder: (context, _) => _demoFor(g, _demo.value),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClayButton(
                        label: "Let's Play!",
                        icon: Icons.play_arrow_rounded,
                        color: AppColors.mintDeep,
                        height: 72,
                        fontSize: 28,
                        onTap: _play,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoFor(GameDef g, double t) {
    return LayoutBuilder(
      builder: (context, c) {
        switch (g) {
          case SortGameDef():
            return _sortDemo(g, t, c);
          case MatchGameDef():
            return _matchDemo(g, t, c);
        }
      },
    );
  }

  /// An example item glides from the top into its basket.
  Widget _sortDemo(SortGameDef g, double t, BoxConstraints c) {
    final cats = g.categories.take(2).toList();
    final item = g.items.firstWhere(
      (i) => i.categoryId == cats.first.id && i.minLevel == 1,
    );
    final basketW = c.maxWidth * 0.4;
    final basketH = c.maxHeight * 0.48;
    final itemS = min(c.maxHeight * 0.38, 100.0);
    final p = Curves.easeInOutCubic.transform((t / 0.75).clamp(0.0, 1.0));
    final start = Offset(c.maxWidth / 2 - itemS / 2, 0);
    final end = Offset(
      c.maxWidth * 0.06 + basketW / 2 - itemS / 2,
      c.maxHeight - basketH * 0.8,
    );
    final pos = Offset.lerp(start, end, p)!;
    final landed = t > 0.75;
    return Stack(
      children: [
        for (var i = 0; i < cats.length; i++)
          Positioned(
            left: i == 0 ? c.maxWidth * 0.06 : null,
            right: i == 1 ? c.maxWidth * 0.06 : null,
            bottom: 0,
            width: basketW,
            height: basketH,
            child: Transform.scale(
              scale: (i == 0 && landed) ? 1.06 : 1,
              child: ClayContainer(
                color: cats[i].color,
                radius: 26,
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(child: ItemArt(cats[i].icon, size: 60)),
                    ),
                    Text(
                      cats[i].label,
                      style: AppText.title(17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!landed)
          Positioned(
            left: pos.dx,
            top: pos.dy,
            child: ClayContainer(
              color: Colors.white,
              radius: itemS * 0.26,
              width: itemS,
              height: itemS,
              padding: EdgeInsets.all(itemS * 0.1),
              child: ItemArt(item.visual, size: itemS * 0.8),
            ),
          ),
        if (p > 0.1 && p < 0.9)
          Positioned(
            left: pos.dx + itemS * 0.6,
            top: pos.dy + itemS * 0.6,
            child: const Text('👆', style: TextStyle(fontSize: 40)),
          ),
        if (landed)
          const Align(
            alignment: Alignment(-0.55, -0.6),
            child: Text('✨🎉✨', style: TextStyle(fontSize: 34)),
          ),
      ],
    );
  }

  /// Two cards that belong together slide into one frame.
  Widget _matchDemo(MatchGameDef g, double t, BoxConstraints c) {
    final pair = MatchEngine.availablePairs(g, Level.veryEasy, 1).first;
    final s = min(c.maxHeight * 0.6, c.maxWidth * 0.32);
    final p = Curves.easeInOutCubic.transform((t / 0.7).clamp(0.0, 1.0));
    final gap = (c.maxWidth - s * 2) * 0.5 * (1 - p);
    final joined = t > 0.7;
    final isSeq = pair.a.visual is SequenceVisual;
    Widget card(Visual v) => ClayContainer(
      color: joined ? const Color(0xFFD9F7E8) : Colors.white,
      radius: s * 0.24,
      width: s,
      height: s,
      padding: EdgeInsets.all(s * 0.08),
      child: FittedBox(child: ItemArt(v, size: s * 0.84)),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            card(pair.a.visual),
            SizedBox(width: max(8, gap)),
            card(pair.b.visual),
          ],
        ),
        if (joined)
          Positioned(
            top: 0,
            child: Text(
              isSeq ? '✨' : '💖',
              style: const TextStyle(fontSize: 40),
            ),
          ),
        if (!joined)
          Positioned(
            bottom: 0,
            child: Text(
              '👆',
              style: TextStyle(fontSize: 36 + 4 * sin(t * pi * 4)),
            ),
          ),
      ],
    );
  }
}
