import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/game_models.dart';
import '../services/app_scope.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clay.dart';
import '../widgets/item_art.dart';

/// Grown-up settings. Reached only through the parent gate and kept apart
/// from the child-facing screens.
class ParentZoneScreen extends StatelessWidget {
  const ParentZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.lavender,
        title: Text('Parent Zone', style: AppText.display(24)),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([app.settings, app.rewards]),
        builder: (context, _) {
          final s = app.settings;
          final r = app.rewards;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _Section(
                title: 'Child',
                emoji: '🧒',
                children: [
                  Text(
                    'Age group (starting difficulty)',
                    style: AppText.body(15),
                  ),
                  const SizedBox(height: 8),
                  _Choice<AgeGroup>(
                    values: AgeGroup.values,
                    selected: s.ageGroup,
                    label: (a) => '${a.emoji} ${a.ages}',
                    onSelect: (a) => s.update((x) => x.ageGroup = a),
                  ),
                  const SizedBox(height: 16),
                  Text('Difficulty', style: AppText.body(15)),
                  const SizedBox(height: 8),
                  _Choice<int?>(
                    values: const [null, 1, 2, 3],
                    selected: s.fixedLevel,
                    label: (v) => v == null
                        ? '✨ Auto'
                        : '${Level.fromValue(v).emoji} ${Level.fromValue(v).label}',
                    onSelect: (v) => s.update((x) => x.fixedLevel = v),
                  ),
                  _Switch(
                    'Grow difficulty as they succeed',
                    'Auto mode moves up after two smooth rounds',
                    s.adaptive,
                    (v) => s.update((x) => x.adaptive = v),
                  ),
                ],
              ),
              _Section(
                title: 'Play style',
                emoji: '👆',
                children: [
                  _Choice<InteractionMode>(
                    values: InteractionMode.values,
                    selected: s.interaction,
                    label: (m) => m.label,
                    onSelect: (m) => s.update((x) => x.interaction = m),
                  ),
                  _Switch(
                    'Automatic hints',
                    'Gently pulse the answer after 5 seconds idle',
                    s.autoHints,
                    (v) => s.update((x) => x.autoHints = v),
                  ),
                  _Switch(
                    'Light up the right basket',
                    'On Very Easy, when a picture is picked',
                    s.assistHighlight,
                    (v) => s.update((x) => x.assistHighlight = v),
                  ),
                  _Switch(
                    'Timed play',
                    'Optional - rounds still end with a celebration',
                    s.timerEnabled,
                    (v) => s.update((x) => x.timerEnabled = v),
                  ),
                  if (s.timerEnabled)
                    _Slider(
                      'Timer length',
                      s.timerSeconds.toDouble(),
                      30,
                      300,
                      '${s.timerSeconds} s',
                      (v) => s.update((x) => x.timerSeconds = v.round()),
                    ),
                ],
              ),
              _Section(
                title: 'Sound & comfort',
                emoji: '🔊',
                children: [
                  _Switch(
                    'Sound effects',
                    'Soft chimes and pops',
                    s.soundEffects,
                    (v) => s.update((x) => x.soundEffects = v),
                  ),
                  _Switch(
                    'Voice',
                    'Reads instructions and names pictures aloud',
                    s.voice,
                    (v) => s.update((x) => x.voice = v),
                  ),
                  _Switch(
                    'Haptic feedback',
                    'Little vibrations on taps',
                    s.haptics,
                    (v) => s.update((x) => x.haptics = v),
                  ),
                  _Switch(
                    'Reduced motion',
                    'Calmer animations, no confetti',
                    s.reducedMotion,
                    (v) => s.update((x) => x.reducedMotion = v),
                  ),
                  _Switch(
                    'Show rewards',
                    'Star counter (celebrations always show)',
                    s.rewardsVisible,
                    (v) => s.update((x) => x.rewardsVisible = v),
                  ),
                ],
              ),
              _Section(
                title: 'Screen time',
                emoji: '⏰',
                children: [
                  _Slider(
                    'Suggest a break after',
                    s.sessionMinutes.toDouble(),
                    5,
                    60,
                    '${s.sessionMinutes} min',
                    (v) => s.update((x) => x.sessionMinutes = v.round()),
                  ),
                  _Slider(
                    'Daily limit',
                    s.dailyLimitMinutes.toDouble(),
                    0,
                    180,
                    s.dailyLimitMinutes == 0
                        ? 'No limit'
                        : '${s.dailyLimitMinutes} min',
                    (v) => s.update(
                      (x) => x.dailyLimitMinutes = (v / 5).round() * 5,
                    ),
                  ),
                  Text(
                    'Played today: ${r.minutesToday} min',
                    style: AppText.body(15, color: AppColors.inkSoft),
                  ),
                ],
              ),
              _Section(
                title: 'Progress',
                emoji: '📈',
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ClayPill(
                        emoji: '🎯',
                        text: '${r.roundsCompleted} rounds',
                      ),
                      ClayPill(emoji: '⭐', text: '${r.stars}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final g in allGames.where(
                    (g) => (r.progress[g.id]?.rounds ?? 0) > 0,
                  ))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        g.cover,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(g.title, style: AppText.body(15)),
                      trailing: Text(
                        '${r.progress[g.id]!.rounds} rounds · ${r.levelFor(g, s).label}',
                        style: AppText.body(13, color: AppColors.inkSoft),
                      ),
                    ),
                ],
              ),
              _Section(
                title: 'Games',
                emoji: '🎮',
                children: [
                  Text(
                    'Switch games on or off. Tap a game to choose its pictures and basket names.',
                    style: AppText.body(14, color: AppColors.inkSoft),
                  ),
                  for (final kind in GameKind.values) ...[
                    const SizedBox(height: 12),
                    Text(
                      kind == GameKind.sort
                          ? 'Sorting games'
                          : 'Matching games',
                      style: AppText.title(18),
                    ),
                    for (final g in allGames.where((g) => g.kind == kind))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(
                          g.cover,
                          style: const TextStyle(fontSize: 26),
                        ),
                        title: Text(
                          '${g.number}. ${g.title}',
                          style: AppText.body(15),
                        ),
                        subtitle: Text(
                          'Ages ${g.minAge}+',
                          style: AppText.body(12, color: AppColors.inkSoft),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameContentScreen(game: g),
                          ),
                        ),
                        trailing: Switch(
                          value: s.isGameEnabled(g.id),
                          onChanged: (v) => s.update((x) {
                            v
                                ? x.disabledGames.remove(g.id)
                                : x.disabledGames.add(g.id);
                          }),
                        ),
                      ),
                  ],
                ],
              ),
              _Section(
                title: 'Reset',
                emoji: '🧹',
                children: [
                  ClayButton(
                    label: 'Reset progress & stars',
                    color: AppColors.coralDeep,
                    fontSize: 18,
                    height: 56,
                    expand: true,
                    onTap: () => _confirm(
                      context,
                      'Reset all progress and stars?',
                      r.resetAll,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClayButton(
                    label: 'Restore default settings',
                    color: AppColors.skyDeep,
                    fontSize: 18,
                    height: 56,
                    expand: true,
                    onTap: () => _confirm(
                      context,
                      'Restore all settings to their defaults?',
                      s.resetToDefaults,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String message,
    VoidCallback action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Are you sure?', style: AppText.title(22)),
        content: Text(message, style: AppText.body(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok == true) action();
  }
}

/// Per-game content controls: categories, individual pictures and
/// renamable basket labels.
class GameContentScreen extends StatelessWidget {
  const GameContentScreen({super.key, required this.game});
  final GameDef game;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).settings;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.lavender,
        title: Text(game.title, style: AppText.title(20)),
      ),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final g = game;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(g.instruction, style: AppText.body(16)),
              if (g.parentNote != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sunny.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('💡 ${g.parentNote}', style: AppText.body(14)),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'If too much is switched off to make a round, the game quietly uses its default set.',
                style: AppText.body(13, color: AppColors.inkSoft),
              ),
              ...switch (g) {
                SortGameDef() => _sortControls(g, s),
                MatchGameDef() => _matchControls(g, s),
              },
            ],
          );
        },
      ),
    );
  }

  List<Widget> _sortControls(SortGameDef g, SettingsController s) => [
    const SizedBox(height: 16),
    Text('Baskets', style: AppText.title(20)),
    for (final c in g.categories)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: ItemArt(c.icon, size: 36)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: s.labelOverrides[g.id]?[c.id] ?? '',
                decoration: InputDecoration(
                  hintText: c.label,
                  labelText: 'Name (from level ${c.minLevel})',
                  isDense: true,
                ),
                onChanged: (v) => s.update((x) {
                  x.labelOverrides.putIfAbsent(g.id, () => {})[c.id] = v;
                }),
              ),
            ),
            Switch(
              value: !s.categoriesOff(g.id).contains(c.id),
              onChanged: (_) => s.toggleIn(s.disabledCategories, g.id, c.id),
            ),
          ],
        ),
      ),
    const SizedBox(height: 16),
    Text('Pictures', style: AppText.title(20)),
    for (final i in g.items)
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: SizedBox(
          width: 44,
          height: 44,
          child: ItemArt(i.visual, size: 44),
        ),
        title: Text(i.name, style: AppText.body(15)),
        subtitle: Text(
          '${g.categories.firstWhere((c) => c.id == i.categoryId).label} · level ${i.minLevel}',
          style: AppText.body(12, color: AppColors.inkSoft),
        ),
        value: !s.itemsOff(g.id).contains(i.id),
        onChanged: (_) => s.toggleIn(s.disabledItems, g.id, i.id),
      ),
  ];

  List<Widget> _matchControls(MatchGameDef g, SettingsController s) {
    if (g.generator != null) {
      return [
        const SizedBox(height: 16),
        Text(
          'Patterns are made fresh each round (colours, shapes and fruit).',
          style: AppText.body(15),
        ),
      ];
    }
    final seen = <String>{};
    final pairs = g.pairs.where((p) => seen.add(p.a.key)).toList();
    return [
      const SizedBox(height: 16),
      Text('Pairs (${g.rule.description})', style: AppText.title(20)),
      for (final p in pairs)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: SizedBox(
            width: 92,
            height: 44,
            child: Row(
              children: [
                ItemArt(p.a.visual, size: 44),
                const SizedBox(width: 4),
                ItemArt(p.b.visual, size: 44),
              ],
            ),
          ),
          title: Text(p.a.name, style: AppText.body(15)),
          subtitle: Text(
            'level ${p.minLevel}',
            style: AppText.body(12, color: AppColors.inkSoft),
          ),
          value: !s.itemsOff(g.id).contains(p.a.key),
          onChanged: (_) => s.toggleIn(s.disabledItems, g.id, p.a.key),
        ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emoji,
    required this.children,
  });
  final String title;
  final String emoji;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ClayContainer(
        color: Colors.white,
        radius: 28,
        depth: 0.7,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Text(title, style: AppText.display(22)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch(this.title, this.subtitle, this.value, this.onChanged);
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: AppText.body(16)),
    subtitle: Text(
      subtitle,
      style: AppText.body(13, color: AppColors.inkSoft, weight: 600),
    ),
    value: value,
    onChanged: onChanged,
  );
}

class _Slider extends StatelessWidget {
  const _Slider(
    this.title,
    this.value,
    this.min,
    this.max,
    this.display,
    this.onChanged,
  );
  final String title;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: AppText.body(16))),
          Text(
            display,
            style: AppText.title(16, color: AppColors.lavenderDeep),
          ),
        ],
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    ],
  );
}

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(label(v), style: AppText.body(15)),
          selected: v == selected,
          selectedColor: AppColors.mint,
          backgroundColor: AppColors.cream,
          onSelected: (_) => onSelect(v),
        ),
    ],
  );
}
