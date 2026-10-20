import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../services/app_scope.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/garden_background.dart';
import 'celebration_screen.dart';
import 'game_intro_screen.dart';
import 'game_router.dart';

const praise = [
  'Great job!',
  'Yay, you did it!',
  'Super!',
  'Wonderful!',
  'Brilliant!',
  'Well done!',
];

/// Shared behaviour for every gameplay screen: session id, optional timer,
/// pause / resume (also on app backgrounding), idle hints, play-time
/// tracking and the round-complete hand-off. Sorting and matching screens
/// only build their board.
abstract class GameShellState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  GameDef get game;

  /// Items done / total, for the progress bar.
  int get done;
  int get total;
  String get celebrationTitle;

  Widget buildBoard(BuildContext context, BoxConstraints constraints);

  /// Called when the child has been idle for a few seconds.
  void onIdleHint();

  late final String sessionId =
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
  late AppScope app;
  late Level level;
  final Random rnd = Random();
  bool paused = false;
  bool hinting = false;
  bool _finished = false;
  bool _appActive = true;
  int? secondsLeft;
  Timer? _ticker;
  Timer? _idle;
  bool _started = false;

  bool get reducedMotion => app.settings.reducedMotion;
  bool get dragEnabled =>
      app.settings.interaction == InteractionMode.tapAndDrag;
  AudioService get audio => app.audio;

  /// Build the round. Called once with [level] already resolved.
  void startRound();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    app = AppScope.of(context);
    if (!_started) {
      _started = true;
      level = app.rewards.levelFor(game, app.settings);
      startRound();
      WidgetsBinding.instance.addObserver(this);
      if (app.settings.timerEnabled) secondsLeft = app.settings.timerSeconds;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      resetIdle();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) audio.speak(game.instruction);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _idle?.cancel();
    audio.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (!_appActive && !paused && !_finished) setState(() => paused = true);
  }

  void _tick() {
    if (paused || !_appActive || _finished) return;
    app.rewards.addPlaySeconds(1);
    final left = secondsLeft;
    if (left != null) {
      setState(() => secondsLeft = left - 1);
      // Time's up is still a celebration - never a failure.
      if (left - 1 <= 0) finishRound(correct: done, mistakes: 0);
    }
  }

  void resetIdle() {
    _idle?.cancel();
    if (hinting) setState(() => hinting = false);
    if (!app.settings.autoHints) return;
    _idle = Timer(const Duration(seconds: 5), () {
      if (!mounted || paused || _finished) return;
      setState(() => hinting = true);
      onIdleHint();
    });
  }

  /// Call on every child interaction.
  void interacted() => resetIdle();

  void finishRound({required int correct, required int mistakes}) {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();
    _idle?.cancel();
    final reward = app.rewards.completeRound(
      sessionId: sessionId,
      game: game,
      level: level,
      correct: correct,
      mistakes: mistakes,
      settings: app.settings,
    );
    audio.sfx(Sfx.celebrate);
    audio.speak(celebrationTitle);
    Future.delayed(Duration(milliseconds: reducedMotion ? 200 : 700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CelebrationScreen(
            game: game,
            title: celebrationTitle,
            completed: correct,
            reward: reward,
          ),
        ),
      );
    });
  }

  void _togglePause() {
    setState(() => paused = !paused);
    if (!paused) resetIdle();
  }

  void _restart() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => gameScreenFor(game)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: GardenBackground(
          theme: game.theme,
          animate: !reducedMotion,
          showSun: false,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _topBar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: LayoutBuilder(
                          builder: (context, c) => buildBoard(context, c),
                        ),
                      ),
                    ),
                  ],
                ),
                if (paused) _pauseOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final s = app.settings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          ClayIconButton(
            icon: Icons.home_rounded,
            semanticLabel: 'Home',
            size: 56,
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          const SizedBox(width: 10),
          Expanded(child: _progressBar()),
          const SizedBox(width: 10),
          if (secondsLeft != null) ...[
            ClayPill(emoji: '⏱️', text: '${max(0, secondsLeft!)}'),
            const SizedBox(width: 8),
          ],
          if (s.rewardsVisible) ...[
            ListenableBuilder(
              listenable: app.rewards,
              builder: (_, _) =>
                  ClayPill(emoji: '⭐', text: '${app.rewards.stars}'),
            ),
            const SizedBox(width: 8),
          ],
          ClayIconButton(
            icon: Icons.pause_rounded,
            semanticLabel: 'Pause',
            size: 56,
            color: AppColors.sunny,
            onTap: _togglePause,
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final frac = total == 0 ? 0.0 : done / total;
    return Semantics(
      label: '$done of $total done',
      child: ClayContainer(
        color: Colors.white,
        radius: 20,
        depth: 0.6,
        height: 36,
        padding: const EdgeInsets.all(5),
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                width: max(26, c.maxWidth * frac),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.mint, AppColors.mintDeep],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Center(child: Text('$done / $total', style: AppText.title(16))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.ink.withValues(alpha: 0.45),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ClayContainer(
              color: AppColors.cream,
              radius: 40,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😴', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Text(
                    'Taking a little break',
                    style: AppText.display(26),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ClayButton(
                    label: 'Keep Playing',
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.mintDeep,
                    expand: true,
                    onTap: _togglePause,
                  ),
                  const SizedBox(height: 14),
                  ClayButton(
                    label: 'Start Over',
                    icon: Icons.refresh_rounded,
                    color: AppColors.skyDeep,
                    expand: true,
                    onTap: _restart,
                  ),
                  const SizedBox(height: 14),
                  ClayButton(
                    label: 'How to Play',
                    icon: Icons.help_rounded,
                    color: AppColors.lavenderDeep,
                    expand: true,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameIntroScreen(game: game),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClayButton(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    color: AppColors.coralDeep,
                    expand: true,
                    onTap: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
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
