import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/match_engine.dart';
import '../models/game_models.dart';
import '../models/visual.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/effects.dart';
import '../widgets/item_art.dart';
import 'game_shell.dart';

/// Prompt-style matching: one big card, two to four answers. Powers colour,
/// shape, shadow, letter-to-object, sounds, homes, habitats, weather,
/// numbers, uses, rooms, patterns, colour words and day/night.
class MatchPromptScreen extends StatefulWidget {
  const MatchPromptScreen({super.key, required this.game});
  final MatchGameDef game;

  @override
  State<MatchPromptScreen> createState() => _MatchPromptScreenState();
}

class _MatchPromptScreenState extends GameShellState<MatchPromptScreen> {
  late PromptSession session;
  final Map<String, int> _wiggles = {};
  bool _solved = false;
  int _burst = 0;
  String? _hover;
  Timer? _advance;

  @override
  MatchGameDef get game => widget.game;
  @override
  int get done => session.solvedCount;
  @override
  int get total => session.total;
  @override
  String get celebrationTitle => game.celebration ?? 'Wonderful Matching!';

  @override
  void startRound() {
    session = PromptSession(
      MatchEngine.buildPrompts(
        game,
        level,
        rnd,
        disabledKeys: app.settings.itemsOff(game.id),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _speakPrompt() {
    final step = session.current;
    if (step == null || !mounted) return;
    audio.speak(step.prompt.spoken ?? step.prompt.name);
  }

  @override
  void onIdleHint() => setState(() {});

  void _choose(MatchCard card) {
    if (_solved) return;
    interacted();
    final outcome = session.choose(card.id);
    switch (outcome) {
      case PromptOutcome.correct:
        app.rewards.awardPoint(sessionId, '${session.index}');
        audio.sfx(Sfx.match);
        audio.haptic();
        audio.speak(
          '${praise[rnd.nextInt(praise.length)]} ${card.spoken ?? card.name}',
        );
        setState(() {
          _solved = true;
          _burst++;
        });
        _advance = Timer(
          Duration(milliseconds: reducedMotion ? 800 : 1300),
          () {
            if (!mounted) return;
            if (session.isComplete) {
              finishRound(
                correct: session.solvedCount,
                mistakes: session.mistakes,
              );
              return;
            }
            setState(() {
              session.advance();
              _solved = false;
            });
            _speakPrompt();
            resetIdle();
          },
        );
      case PromptOutcome.tryAgain:
        audio.sfx(Sfx.tryAgain);
        audio.speak(card.spoken ?? card.name);
        setState(() => _wiggles[card.id] = (_wiggles[card.id] ?? 0) + 1);
      case PromptOutcome.ignored:
        break;
    }
  }

  @override
  Widget buildBoard(BuildContext context, BoxConstraints c) {
    final step = session.current;
    if (step == null) return const SizedBox.shrink();
    final choices = step.choices;
    final promptH = (c.maxHeight * 0.38).clamp(120.0, 260.0);
    final isSeq = step.prompt.visual is SequenceVisual;
    final cols = choices.length <= 3 ? choices.length : 2;
    final rows = (choices.length / cols).ceil();
    final choiceAreaH = c.maxHeight - promptH - 100;
    final choiceSize = min(
      (c.maxWidth - 20 * (cols + 1)) / cols,
      (choiceAreaH - 18 * rows) / rows,
    ).clamp(80.0, 170.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SizedBox(
              height: 60,
              child: Center(
                child: HintBubble(text: game.instruction, emoji: '👀'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: promptH,
              child: Center(
                child: _promptCard(step, promptH, c.maxWidth, isSeq),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 18,
                  children: [
                    for (final ch in choices) _choice(ch, step, choiceSize),
                  ],
                ),
              ),
            ),
          ],
        ),
        SparkleBurst(trigger: _burst, reducedMotion: reducedMotion, size: 280),
      ],
    );
  }

  Widget _promptCard(PromptStep step, double h, double maxW, bool isSeq) {
    final p = step.prompt;
    final artSize = h * 0.74;
    final hasVoice = app.settings.voice;
    final card = ClayContainer(
      color: AppColors.cream,
      radius: 36,
      depth: 1.3,
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW - 28),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxW - 140,
                  maxHeight: artSize,
                ),
                child: FittedBox(child: ItemArt(p.visual, size: artSize)),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _solved
                    ? Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('💖', style: TextStyle(fontSize: 30)),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isSeq ? artSize * 0.6 : artSize,
                            ),
                            child: ItemArt(
                              step.answer.visual,
                              size: isSeq ? artSize * 0.6 : artSize * 0.8,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );

    final speaker = (hasVoice || p.spoken != null)
        ? Positioned(
            right: -6,
            top: -6,
            child: ClayIconButton(
              icon: Icons.volume_up_rounded,
              semanticLabel: 'Hear it',
              size: 48,
              color: AppColors.sky,
              onTap: () {
                interacted();
                _speakPrompt();
              },
            ),
          )
        : null;

    final body = Stack(clipBehavior: Clip.none, children: [card, ?speaker]);
    if (!dragEnabled || _solved) return Semantics(label: p.name, child: body);
    return Semantics(
      label: p.name,
      child: Draggable<String>(
        data: p.id,
        onDragStarted: interacted,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.9,
            child: ClayContainer(
              color: AppColors.cream,
              radius: 30,
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: artSize * 0.6,
                child: FittedBox(child: ItemArt(p.visual, size: artSize * 0.6)),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: body),
        child: body,
      ),
    );
  }

  Widget _choice(MatchCard card, PromptStep step, double size) {
    final isAnswer = card.id == step.answer.id;
    final isHint = hinting && isAnswer;
    final hover = _hover == card.id;
    final faded = _solved && !isAnswer;

    final face = ClayContainer(
      color: _solved && isAnswer ? const Color(0xFFD9F7E8) : Colors.white,
      radius: size * 0.24,
      width: size,
      height: size,
      depth: hover ? 1.5 : 1,
      borderColor: hover ? AppColors.sunnyDeep : null,
      borderWidth: hover ? 5 : 0,
      padding: EdgeInsets.all(size * 0.08),
      child: ItemArt(card.visual, size: size * 0.84),
    );

    return AnimatedOpacity(
      key: ValueKey('${session.index}-${card.id}'),
      duration: const Duration(milliseconds: 250),
      opacity: faded ? 0.35 : 1,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) {
          setState(() => _hover = card.id);
          return true;
        },
        onLeave: (_) => setState(() => _hover = null),
        onAcceptWithDetails: (_) {
          setState(() => _hover = null);
          _choose(card);
        },
        builder: (context, _, _) => Squishy(
          onTap: () => _choose(card),
          semanticLabel: card.name,
          haptics: app.settings.haptics,
          child: Wiggle(
            trigger: _wiggles[card.id] ?? 0,
            reducedMotion: reducedMotion,
            child: Pulse(
              active: isHint,
              reducedMotion: reducedMotion,
              child: face,
            ),
          ),
        ),
      ),
    );
  }
}
