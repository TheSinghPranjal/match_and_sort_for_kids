import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/sort_engine.dart';
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/effects.dart';
import '../widgets/item_art.dart';
import 'game_shell.dart';

/// One screen for all 25 sorting activities.
class SortGameScreen extends StatefulWidget {
  const SortGameScreen({super.key, required this.game});
  final SortGameDef game;

  @override
  State<SortGameScreen> createState() => _SortGameScreenState();
}

class _SortGameScreenState extends GameShellState<SortGameScreen> {
  late SortSession session;
  String? selectedId;

  /// Basket currently glowing (assist highlight, hint or "try here").
  String? glowCategory;
  String? hoverCategory;
  final Map<String, int> _wiggles = {};
  final Map<String, int> _bursts = {};
  String? bubble;
  String bubbleEmoji = '💡';
  Timer? _bubbleTimer;
  Timer? _glowTimer;

  @override
  SortGameDef get game => widget.game;
  @override
  int get done => session.sortedCount;
  @override
  int get total => session.total;
  @override
  String get celebrationTitle => game.celebration ?? 'Amazing Sorting!';

  @override
  void startRound() {
    session = SortSession(
      SortEngine.buildRound(
        game,
        level,
        rnd,
        disabledItems: app.settings.itemsOff(game.id),
        disabledCategories: app.settings.categoriesOff(game.id),
      ),
    );
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _glowTimer?.cancel();
    super.dispose();
  }

  String _label(GameCategory c) => app.settings.label(game.id, c.id, c.label);

  void _say(String text, {String emoji = '💡', int ms = 1800}) {
    _bubbleTimer?.cancel();
    setState(() {
      bubble = text;
      bubbleEmoji = emoji;
    });
    _bubbleTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => bubble = null);
    });
  }

  void _glow(String? catId, {int ms = 1600}) {
    _glowTimer?.cancel();
    setState(() => glowCategory = catId);
    if (catId != null) {
      _glowTimer = Timer(Duration(milliseconds: ms), () {
        if (mounted && selectedId == null) setState(() => glowCategory = null);
      });
    }
  }

  @override
  void onIdleHint() {
    final item = session.hintItem;
    if (item == null) return;
    setState(() {
      glowCategory = item.categoryId;
      _wiggles[item.id] = (_wiggles[item.id] ?? 0) + 1;
    });
  }

  void _select(SortItem item) {
    interacted();
    audio.sfx(Sfx.pop);
    audio.speak(item.name);
    final again = selectedId == item.id;
    setState(() {
      selectedId = again ? null : item.id;
      final assist = app.settings.assistHighlight && level == Level.veryEasy;
      glowCategory = (!again && assist) ? item.categoryId : null;
    });
  }

  void _placeSelected(GameCategory cat) {
    final id = selectedId;
    if (id == null) {
      // Tapping a basket with nothing picked: nudge the child gently.
      _say('Pick a picture first!', emoji: '👆');
      final first = session.hintItem;
      if (first != null) {
        setState(() => _wiggles[first.id] = (_wiggles[first.id] ?? 0) + 1);
      }
      return;
    }
    _place(id, cat);
  }

  void _place(String itemId, GameCategory cat) {
    interacted();
    final item = session.slots.firstWhere(
      (s) => s?.id == itemId,
      orElse: () => null,
    );
    if (item == null) return;
    final outcome = session.place(itemId, cat.id);
    switch (outcome) {
      case SortOutcome.correct:
        app.rewards.awardPoint(sessionId, item.id);
        audio.sfx(Sfx.correct);
        audio.haptic();
        audio.speak(
          item.fact ?? '${praise[rnd.nextInt(praise.length)]} ${item.name}!',
        );
        setState(() {
          selectedId = null;
          glowCategory = null;
          _bursts[cat.id] = (_bursts[cat.id] ?? 0) + 1;
        });
        _say(
          item.fact ?? praise[rnd.nextInt(praise.length)],
          emoji: '🎉',
          ms: item.fact != null ? 3000 : 1400,
        );
        if (session.isComplete) {
          finishRound(correct: session.sortedCount, mistakes: session.mistakes);
        }
      case SortOutcome.tryAgain:
        audio.sfx(Sfx.tryAgain);
        final right = session.categoryOf(item);
        setState(() {
          _wiggles[item.id] = (_wiggles[item.id] ?? 0) + 1;
          selectedId = null;
        });
        _glow(right.id, ms: 2200);
        final hint = 'Try ${_label(right)}!';
        _say(hint, emoji: '🤗', ms: 2200);
        audio.speak(hint);
      case SortOutcome.ignored:
        break;
    }
  }

  @override
  Widget buildBoard(BuildContext context, BoxConstraints c) {
    final cats = session.round.categories;
    final bubbleH = 56.0;
    final basketsH = (c.maxHeight * 0.38).clamp(140.0, 300.0);
    final trayH = c.maxHeight - basketsH - bubbleH - 16;
    final slots = session.slots;
    final n = max(1, slots.length);
    final perRow = c.maxWidth > 600 ? n : min(n, 2);
    final rows = (n / perRow).ceil();
    final tile = min(
      min((c.maxWidth - 24 * perRow) / perRow, (trayH - 20 * rows) / rows),
      170.0,
    ).clamp(84.0, 170.0);

    return Column(
      children: [
        SizedBox(
          height: bubbleH,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: bubble != null
                  ? HintBubble(
                      key: ValueKey(bubble),
                      text: bubble!,
                      emoji: bubbleEmoji,
                    )
                  : _instructionChip(),
            ),
          ),
        ),
        SizedBox(
          height: max(0, trayH),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 16,
              children: [
                for (var i = 0; i < slots.length; i++)
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: reducedMotion ? 0 : 350),
                    transitionBuilder: (child, a) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: a,
                        curve: Curves.easeOutBack,
                      ),
                      child: child,
                    ),
                    child: slots[i] == null
                        ? SizedBox.square(
                            key: ValueKey('empty$i'),
                            dimension: tile,
                          )
                        : _itemTile(slots[i]!, tile),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(height: basketsH, child: _baskets(cats, basketsH, c.maxWidth)),
      ],
    );
  }

  Widget _instructionChip() {
    return Squishy(
      key: const ValueKey('instruction'),
      onTap: () => app.audio.speak(game.instruction),
      semanticLabel: game.instruction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            const Text('➡️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            const Text('🧺', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                game.title,
                style: AppText.title(18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(SortItem item, double size) {
    final selected = selectedId == item.id;
    final isHint = hinting && session.hintItem?.id == item.id;
    Widget tile(double depth, {bool glow = false}) => ClayContainer(
      color: selected ? const Color(0xFFFFF4C4) : Colors.white,
      radius: size * 0.26,
      width: size,
      height: size,
      depth: depth,
      borderColor: glow ? AppColors.sunnyDeep : null,
      borderWidth: glow ? 5 : 0,
      padding: EdgeInsets.all(size * 0.1),
      child: ItemArt(item.visual, size: size * 0.8),
    );

    final body = Wiggle(
      trigger: _wiggles[item.id] ?? 0,
      reducedMotion: reducedMotion,
      child: Pulse(
        active: isHint,
        reducedMotion: reducedMotion,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 180),
          offset: selected ? const Offset(0, -0.08) : Offset.zero,
          child: tile(selected ? 1.5 : 1, glow: selected),
        ),
      ),
    );

    final tappable = Squishy(
      onTap: () => _select(item),
      semanticLabel: item.name,
      haptics: app.settings.haptics,
      child: body,
    );

    if (!dragEnabled) {
      return KeyedSubtree(key: ValueKey(item.id), child: tappable);
    }
    return Draggable<String>(
      key: ValueKey(item.id),
      data: item.id,
      onDragStarted: () {
        interacted();
        setState(() {
          selectedId = item.id;
          final assist =
              app.settings.assistHighlight && level == Level.veryEasy;
          glowCategory = assist ? item.categoryId : null;
        });
      },
      onDraggableCanceled: (_, _) => setState(() {
        // Dropped outside a basket: the item simply floats back home.
        selectedId = null;
        glowCategory = null;
      }),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.1, child: tile(1.6, glow: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: tile(0)),
      child: tappable,
    );
  }

  Widget _baskets(List<GameCategory> cats, double h, double w) {
    if (cats.length == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                for (final c in cats.take(2))
                  Expanded(child: _basket(c, compact: true)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                for (final c in cats.skip(2))
                  Expanded(child: _basket(c, compact: true)),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in cats)
          Expanded(child: _basket(c, compact: cats.length > 2 && w < 420)),
      ],
    );
  }

  Widget _basket(GameCategory cat, {bool compact = false}) {
    final glow = glowCategory == cat.id;
    final hover = hoverCategory == cat.id;
    final placed = session.placed[cat.id] ?? const [];
    final label = _label(cat);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) {
          setState(() => hoverCategory = cat.id);
          return true;
        },
        onLeave: (_) => setState(() => hoverCategory = null),
        onAcceptWithDetails: (d) {
          setState(() => hoverCategory = null);
          _place(d.data, cat);
        },
        builder: (context, _, _) => Squishy(
          onTap: () => _placeSelected(cat),
          semanticLabel: '$label basket',
          haptics: app.settings.haptics,
          child: Pulse(
            active: glow,
            reducedMotion: reducedMotion,
            amount: 0.05,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, c) {
                    final icon = min(
                      c.maxWidth * 0.5,
                      c.maxHeight * (compact ? 0.42 : 0.45),
                    );
                    return ClayContainer(
                      color: cat.color,
                      radius: 30,
                      depth: hover ? 1.5 : 1,
                      borderColor: (glow || hover) ? Colors.white : null,
                      borderWidth: (glow || hover) ? 6 : 0,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              label,
                              style: AppText.title(compact ? 16 : 20),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(icon * 0.08),
                            child: ItemArt(cat.icon, size: icon),
                          ),
                          _placedRow(placed, compact ? 22 : 28),
                        ],
                      ),
                    );
                  },
                ),
                SparkleBurst(
                  trigger: _bursts[cat.id] ?? 0,
                  reducedMotion: reducedMotion,
                  size: 160,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placedRow(List<SortItem> placed, double size) {
    final shown = placed.length > 4
        ? placed.sublist(placed.length - 4)
        : placed;
    return SizedBox(
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final p in shown) ItemArt(p.visual, size: size),
          if (placed.isEmpty)
            Container(
              width: size * 2,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
