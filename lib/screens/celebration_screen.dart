import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../services/app_scope.dart';
import '../services/rewards_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/effects.dart';
import '../widgets/garden_background.dart';
import 'game_router.dart';

/// End-of-round party. There is no "game over" - every round ends here.
class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({
    super.key,
    required this.game,
    required this.title,
    required this.completed,
    required this.reward,
  });

  final GameDef game;
  final String title;
  final int completed;
  final RoundReward reward;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final reduced = s.reducedMotion;
    final needsBreak =
        app.rewards.sessionLimitReached(s) || app.rewards.dailyLimitReached(s);

    return Scaffold(
      body: GardenBackground(
        theme: game.theme,
        animate: !reduced,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BouncyMascot(reduced: reduced),
                        const SizedBox(height: 8),
                        ClayContainer(
                          color: AppColors.cream,
                          radius: 40,
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                          child: Column(
                            children: [
                              Text(
                                title,
                                style: AppText.display(
                                  34,
                                  color: AppColors.coralDeep,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    game.cover,
                                    style: const TextStyle(fontSize: 34),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$completed done!',
                                    style: AppText.title(26),
                                  ),
                                ],
                              ),
                              if (s.rewardsVisible) ...[
                                const SizedBox(height: 16),
                                ClayPill(
                                  emoji: '⭐',
                                  text: '+${reward.stars}',
                                  color: AppColors.sunny,
                                ),
                              ],
                              if (reward.levelUp != null) ...[
                                const SizedBox(height: 12),
                                HintBubble(
                                  text:
                                      'Ready for ${reward.levelUp!.label} next time!',
                                  emoji: '👏',
                                ),
                              ],
                              if (needsBreak) ...[
                                const SizedBox(height: 12),
                                const HintBubble(
                                  text:
                                      'Great playing! Time to rest your eyes.',
                                  emoji: '😴',
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!app.rewards.dailyLimitReached(s))
                          ClayButton(
                            label: 'Play Again',
                            icon: Icons.replay_rounded,
                            color: AppColors.mintDeep,
                            height: 72,
                            fontSize: 28,
                            expand: true,
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => gameScreenFor(game),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        ClayButton(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          color: AppColors.skyDeep,
                          expand: true,
                          onTap: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: Confetti(enabled: !reduced)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BouncyMascot extends StatefulWidget {
  const _BouncyMascot({required this.reduced});
  final bool reduced;

  @override
  State<_BouncyMascot> createState() => _BouncyMascotState();
}

class _BouncyMascotState extends State<_BouncyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduced) _c.repeat(reverse: true);
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -16 * Curves.easeOut.transform(_c.value)),
        child: child,
      ),
      child: const Text('🐻', style: TextStyle(fontSize: 96)),
    );
  }
}
