import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/match_engine.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../widgets/clay.dart';
import '../widgets/effects.dart';
import '../widgets/item_art.dart';
import '../theme/app_theme.dart';
import 'game_shell.dart';

/// Board-style matching (all cards visible, tap two that belong together).
/// Powers identical pictures, letter partners, animal families, outfits,
/// socks, picture halves and animal look-alikes.
class MatchBoardScreen extends StatefulWidget {
  const MatchBoardScreen({super.key, required this.game});
  final MatchGameDef game;

  @override
  State<MatchBoardScreen> createState() => _MatchBoardScreenState();
}

class _MatchBoardScreenState extends GameShellState<MatchBoardScreen> {
  late BoardSession session;
  final Map<String, int> _wiggles = {};
  (MatchCard, MatchCard)? _celebrating;
  int _burst = 0;
  Timer? _frameTimer;
  String? _hover;

  @override
  MatchGameDef get game => widget.game;
  @override
  int get done => session.matchedCount;
  @override
  int get total => session.total;
  @override
  String get celebrationTitle => game.celebration ?? 'Wonderful Matching!';

  @override
  void startRound() {
    session = BoardSession(
      MatchEngine.buildBoard(
        game,
        level,
        rnd,
        disabledKeys: app.settings.itemsOff(game.id),
      ),
    );
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  @override
  void onIdleHint() => setState(() {});

  void _tap(MatchCard card) {
    interacted();
    final outcome = session.tap(card.id);
    _handle(outcome, card);
  }

  void _handle(BoardOutcome outcome, MatchCard card) {
    switch (outcome) {
      case BoardOutcome.selected:
      case BoardOutcome.switched:
        audio.sfx(Sfx.pop);
        audio.speak(card.spoken ?? card.name);
      case BoardOutcome.matched:
        final (a, b) = session.lastPair!;
        app.rewards.awardPoint(sessionId, a.key);
        audio.sfx(Sfx.match);
        audio.haptic();
        audio.speak(praise[rnd.nextInt(praise.length)]);
        _frameTimer?.cancel();
        setState(() {
          _celebrating = (a, b);
          _burst++;
        });
        _frameTimer = Timer(
          Duration(milliseconds: reducedMotion ? 700 : 1100),
          () {
            if (mounted) setState(() => _celebrating = null);
          },
        );
        if (session.isComplete) {
          finishRound(
            correct: session.matchedCount,
            mistakes: session.mistakes,
          );
        }
      case BoardOutcome.tryAgain:
        final (a, b) = session.lastPair!;
        audio.sfx(Sfx.tryAgain);
        setState(() {
          _wiggles[a.id] = (_wiggles[a.id] ?? 0) + 1;
          _wiggles[b.id] = (_wiggles[b.id] ?? 0) + 1;
        });
      case BoardOutcome.deselected:
      case BoardOutcome.ignored:
        break;
    }
    setState(() {});
  }

  @override
  Widget buildBoard(BuildContext context, BoxConstraints c) {
    final r = session.round;
    final board = r.twoColumns ? _twoColumns(r, c) : _grid(r.left, c);
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SizedBox(
              height: 52,
              child: Center(
                child: HintBubble(text: game.title, emoji: game.cover),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: board),
          ],
        ),
        if (_celebrating != null) _pairFrame(_celebrating!, c),
        SparkleBurst(trigger: _burst, reducedMotion: reducedMotion, size: 260),
      ],
    );
  }

  Widget _twoColumns(BoardRound r, BoxConstraints c) {
    final n = r.left.length;
    final h = c.maxHeight - 60;
    final size = min(
      min((c.maxWidth - 60) / 2, (h - 14 * n) / n),
      160.0,
    ).clamp(70.0, 160.0);
    Widget column(List<MatchCard> cards) => Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [for (final card in cards) _card(card, size)],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        column(r.left),
        // A dotted "path" between the two sides.
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        column(r.right),
      ],
    );
  }

  Widget _grid(List<MatchCard> cards, BoxConstraints c) {
    final n = cards.length;
    final h = c.maxHeight - 60;
    var best = 0.0;
    var bestCols = 2;
    for (var cols = 2; cols <= 5; cols++) {
      final rows = (n / cols).ceil();
      final s = min((c.maxWidth - 16 * cols) / cols, (h - 16 * rows) / rows);
      if (s > best) {
        best = s;
        bestCols = cols;
      }
    }
    final size = best.clamp(70.0, 170.0);
    return Center(
      child: SizedBox(
        width: bestCols * (size + 16),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [for (final card in cards) _card(card, size)],
        ),
      ),
    );
  }

  Widget _card(MatchCard card, double size) {
    final matched = session.matchedIds.contains(card.id);
    final selected = session.selectedId == card.id;
    final isHint = hinting && session.hintCard?.id == card.id;
    final hover = _hover == card.id;

    Widget face(double depth, {bool lifted = false}) => ClayContainer(
      color: matched
          ? const Color(0xFFD9F7E8)
          : (selected ? const Color(0xFFFFF4C4) : Colors.white),
      radius: size * 0.24,
      width: size,
      height: size,
      depth: depth,
      borderColor: (selected || lifted || hover) ? AppColors.sunnyDeep : null,
      borderWidth: (selected || lifted || hover) ? 5 : 0,
      padding: EdgeInsets.all(size * 0.08),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: matched ? 0.55 : 1,
            child: ItemArt(card.visual, size: size * 0.84),
          ),
          if (matched)
            const Align(
              alignment: Alignment.topRight,
              child: Text('✅', style: TextStyle(fontSize: 22)),
            ),
        ],
      ),
    );

    final body = Wiggle(
      trigger: _wiggles[card.id] ?? 0,
      reducedMotion: reducedMotion,
      child: Pulse(
        active: isHint || (selected && !reducedMotion),
        reducedMotion: reducedMotion,
        amount: selected ? 0.04 : 0.07,
        child: face(selected ? 1.5 : (matched ? 0.3 : 1)),
      ),
    );

    final tappable = Squishy(
      onTap: matched ? null : () => _tap(card),
      semanticLabel: matched ? '${card.name}, matched' : card.name,
      haptics: app.settings.haptics,
      child: body,
    );

    final target = DragTarget<String>(
      onWillAcceptWithDetails: (d) {
        if (d.data == card.id || matched) return false;
        setState(() => _hover = card.id);
        return true;
      },
      onLeave: (_) => setState(() => _hover = null),
      onAcceptWithDetails: (d) {
        interacted();
        setState(() => _hover = null);
        _handle(session.tryPair(d.data, card.id), card);
      },
      builder: (context, _, _) => tappable,
    );

    if (!dragEnabled || matched) {
      return KeyedSubtree(key: ValueKey(card.id), child: target);
    }
    return Draggable<String>(
      key: ValueKey(card.id),
      data: card.id,
      onDragStarted: () {
        interacted();
        setState(() => session.selectedId = card.id);
      },
      onDraggableCanceled: (_, _) => setState(() => session.selectedId = null),
      onDragCompleted: () => setState(() {}),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.08, child: face(1.6, lifted: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: face(0)),
      child: target,
    );
  }

  /// The two matched cards snap together into one heart frame.
  Widget _pairFrame((MatchCard, MatchCard) pair, BoxConstraints c) {
    final s = min(c.maxWidth * 0.3, 130.0);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reducedMotion ? 1 : 0.4, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Transform.scale(scale: t, child: child),
        child: ClayContainer(
          color: AppColors.bubblegum,
          radius: 40,
          depth: 1.4,
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mini(pair.$1, s),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('💖', style: TextStyle(fontSize: 34)),
              ),
              _mini(pair.$2, s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(MatchCard card, double s) => Container(
    width: s,
    height: s,
    padding: EdgeInsets.all(s * 0.08),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(s * 0.24),
    ),
    child: ItemArt(card.visual, size: s * 0.84),
  );
}
