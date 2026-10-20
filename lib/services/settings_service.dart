import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';

enum AgeGroup {
  little('Little Explorers', '3-4', '🐣', Level.veryEasy),
  curious('Curious Learners', '5-6', '🦊', Level.easy),
  smart('Smart Explorers', '7-8', '🦉', Level.explorer);

  const AgeGroup(this.title, this.ages, this.emoji, this.startLevel);
  final String title;
  final String ages;
  final String emoji;

  /// Starting difficulty only - parents can pick any level.
  final Level startLevel;
}

enum InteractionMode {
  tapAndDrag('Tap or drag'),
  tapOnly('Tap only');

  const InteractionMode(this.label);
  final String label;
}

/// Parent-controlled settings, persisted as JSON in shared preferences.
/// Every value is validated on load; anything invalid falls back to a safe
/// default so a corrupt store can never break the games.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _load();
  }

  static const _key = 'settings_v1';
  final SharedPreferences? _prefs;

  AgeGroup ageGroup = AgeGroup.little;

  /// null = automatic (age start level + earned progress).
  int? fixedLevel;
  bool adaptive = true;
  InteractionMode interaction = InteractionMode.tapAndDrag;
  bool autoHints = true;

  /// Light up the right basket when an item is picked (Very Easy helper).
  bool assistHighlight = true;
  bool soundEffects = true;
  bool voice = false;
  bool haptics = true;
  bool reducedMotion = false;
  bool rewardsVisible = true;
  bool timerEnabled = false;
  int timerSeconds = 90;
  int sessionMinutes = 20;

  /// 0 = no daily limit.
  int dailyLimitMinutes = 0;
  Set<String> disabledGames = {};
  Map<String, Set<String>> disabledItems = {};
  Map<String, Set<String>> disabledCategories = {};
  Map<String, Map<String, String>> labelOverrides = {};
  Set<String> seenIntros = {};

  bool isGameEnabled(String id) => !disabledGames.contains(id);

  Set<String> itemsOff(String gameId) => disabledItems[gameId] ?? const {};

  Set<String> categoriesOff(String gameId) =>
      disabledCategories[gameId] ?? const {};

  String label(String gameId, String categoryId, String fallback) {
    final v = labelOverrides[gameId]?[categoryId]?.trim();
    return (v == null || v.isEmpty) ? fallback : v;
  }

  void update(void Function(SettingsController s) change) {
    change(this);
    _sanitize();
    notifyListeners();
    _save();
  }

  void toggleIn(Map<String, Set<String>> map, String gameId, String id) {
    update((_) {
      final set = map.putIfAbsent(gameId, () => <String>{});
      if (!set.remove(id)) set.add(id);
    });
  }

  void markIntroSeen(String gameId) {
    if (seenIntros.add(gameId)) {
      notifyListeners();
      _save();
    }
  }

  void resetToDefaults() {
    final seen = seenIntros;
    _applyJson(const {});
    seenIntros = seen;
    notifyListeners();
    _save();
  }

  void _sanitize() {
    timerSeconds = timerSeconds.clamp(30, 300);
    sessionMinutes = sessionMinutes.clamp(5, 60);
    dailyLimitMinutes = dailyLimitMinutes.clamp(0, 180);
    if (fixedLevel != null && (fixedLevel! < 1 || fixedLevel! > 3)) {
      fixedLevel = null;
    }
  }

  void _load() {
    try {
      final raw = _prefs?.getString(_key);
      _applyJson(
        raw == null ? const {} : jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      _applyJson(const {});
    }
    _sanitize();
  }

  void _applyJson(Map<String, dynamic> j) {
    T pick<T>(String k, T fallback) {
      final v = j[k];
      return v is T ? v : fallback;
    }

    Set<String> strings(String k) {
      final v = j[k];
      return v is List ? {for (final x in v) '$x'} : {};
    }

    Map<String, Set<String>> setMap(String k) {
      final v = j[k];
      if (v is! Map) return {};
      return {
        for (final e in v.entries)
          if (e.value is List)
            '${e.key}': {for (final x in e.value as List) '$x'},
      };
    }

    ageGroup =
        AgeGroup.values.asNameMap()[pick<String>('age', '')] ?? AgeGroup.little;
    final lvl = j['level'];
    fixedLevel = lvl is int ? lvl : null;
    adaptive = pick('adaptive', true);
    interaction =
        InteractionMode.values.asNameMap()[pick<String>('interaction', '')] ??
        InteractionMode.tapAndDrag;
    autoHints = pick('hints', true);
    assistHighlight = pick('assist', true);
    soundEffects = pick('sfx', true);
    voice = pick('voice', false);
    haptics = pick('haptics', true);
    reducedMotion = pick('reducedMotion', false);
    rewardsVisible = pick('rewards', true);
    timerEnabled = pick('timer', false);
    timerSeconds = pick('timerSeconds', 90);
    sessionMinutes = pick('sessionMinutes', 20);
    dailyLimitMinutes = pick('dailyLimit', 0);
    disabledGames = strings('disabledGames');
    disabledItems = setMap('disabledItems');
    disabledCategories = setMap('disabledCategories');
    final labels = j['labels'];
    labelOverrides = labels is Map
        ? {
            for (final e in labels.entries)
              if (e.value is Map)
                '${e.key}': {
                  for (final l in (e.value as Map).entries)
                    '${l.key}': '${l.value}',
                },
          }
        : {};
    seenIntros = strings('seenIntros');
  }

  Map<String, dynamic> toJson() => {
    'age': ageGroup.name,
    'level': fixedLevel,
    'adaptive': adaptive,
    'interaction': interaction.name,
    'hints': autoHints,
    'assist': assistHighlight,
    'sfx': soundEffects,
    'voice': voice,
    'haptics': haptics,
    'reducedMotion': reducedMotion,
    'rewards': rewardsVisible,
    'timer': timerEnabled,
    'timerSeconds': timerSeconds,
    'sessionMinutes': sessionMinutes,
    'dailyLimit': dailyLimitMinutes,
    'disabledGames': disabledGames.toList(),
    'disabledItems': disabledItems.map((k, v) => MapEntry(k, v.toList())),
    'disabledCategories': disabledCategories.map(
      (k, v) => MapEntry(k, v.toList()),
    ),
    'labels': labelOverrides,
    'seenIntros': seenIntros.toList(),
  };

  void _save() {
    _prefs?.setString(_key, jsonEncode(toJson()));
  }
}
