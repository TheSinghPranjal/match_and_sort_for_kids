import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';
import 'settings_service.dart';

class GameProgress {
  GameProgress({this.rounds = 0, this.levelBonus = 0, this.cleanStreak = 0});
  int rounds;

  /// Levels earned above the age start level (adaptive progression).
  int levelBonus;
  int cleanStreak;

  Map<String, dynamic> toJson() => {
    'r': rounds,
    'b': levelBonus,
    'c': cleanStreak,
  };

  static GameProgress fromJson(Object? j) {
    if (j is! Map) return GameProgress();
    int i(String k) => j[k] is int ? j[k] as int : 0;
    return GameProgress(
      rounds: i('r').clamp(0, 1 << 30),
      levelBonus: i('b').clamp(0, 2),
      cleanStreak: i('c').clamp(0, 10),
    );
  }
}

/// What a finished round earned: the stars collected during it.
class RoundReward {
  const RoundReward({required this.stars, required this.levelUp});
  final int stars;
  final Level? levelUp;
}

/// The one reward system: stars. A child earns one star for every right
/// answer, in sorting and matching alike. Each star is keyed by session and
/// action, so replays, rebuilds or double taps can never pay twice, and
/// mistakes never take a star away.
class RewardsController extends ChangeNotifier {
  RewardsController(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _load();
  }

  static const _key = 'rewards_v2';
  static const _legacyKey = 'rewards_v1';
  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  int stars = 0;
  int roundsCompleted = 0;
  String usageDay = '';
  int playSecondsToday = 0;
  Map<String, GameProgress> progress = {};

  final Set<String> _starKeys = {};
  final Map<String, int> _sessionStars = {};
  final Map<String, RoundReward> _roundAwards = {};

  /// Seconds played since the app opened (for the session-length nudge).
  int sessionSeconds = 0;

  String get _today {
    final d = _clock();
    return '${d.year}-${d.month}-${d.day}';
  }

  GameProgress progressOf(String gameId) =>
      progress.putIfAbsent(gameId, GameProgress.new);

  Level levelFor(GameDef game, SettingsController s) {
    final fixed = s.fixedLevel;
    if (fixed != null) return Level.fromValue(fixed);
    final bonus = s.adaptive ? (progress[game.id]?.levelBonus ?? 0) : 0;
    return Level.fromValue((s.ageGroup.startLevel.value + bonus).clamp(1, 3));
  }

  /// One star per correct action. Returns false if already awarded.
  bool awardStar(String sessionId, String actionId) {
    if (!_starKeys.add('$sessionId/$actionId')) return false;
    stars++;
    _sessionStars[sessionId] = (_sessionStars[sessionId] ?? 0) + 1;
    notifyListeners();
    _save();
    return true;
  }

  RoundReward completeRound({
    required String sessionId,
    required GameDef game,
    required Level level,
    required int correct,
    required int mistakes,
    required SettingsController settings,
  }) {
    final existing = _roundAwards[sessionId];
    if (existing != null) return existing;

    final gp = progressOf(game.id);
    gp.rounds++;
    roundsCompleted++;

    // Adaptive difficulty: two smooth rounds in a row moves up a level;
    // a really bumpy round quietly eases back down.
    Level? levelUp;
    if (settings.adaptive && settings.fixedLevel == null) {
      if (mistakes <= 1) {
        gp.cleanStreak++;
        if (gp.cleanStreak >= 2 && level != Level.explorer) {
          gp.levelBonus = (gp.levelBonus + 1).clamp(0, 2);
          gp.cleanStreak = 0;
          levelUp = Level.fromValue(level.value + 1);
        }
      } else {
        gp.cleanStreak = 0;
        if (mistakes >= correct * 2 && gp.levelBonus > 0) gp.levelBonus--;
      }
    }

    final reward = RoundReward(
      stars: _sessionStars[sessionId] ?? 0,
      levelUp: levelUp,
    );
    _roundAwards[sessionId] = reward;
    notifyListeners();
    _save();
    return reward;
  }

  void addPlaySeconds(int seconds) {
    final today = _today;
    if (usageDay != today) {
      usageDay = today;
      playSecondsToday = 0;
    }
    playSecondsToday += seconds;
    sessionSeconds += seconds;
    if (playSecondsToday % 15 == 0) _save();
  }

  int get minutesToday => usageDay == _today ? playSecondsToday ~/ 60 : 0;

  /// Parent-approved extra time for today.
  int bonusMinutesToday = 0;

  bool dailyLimitReached(SettingsController s) =>
      s.dailyLimitMinutes > 0 &&
      minutesToday >= s.dailyLimitMinutes + bonusMinutesToday;

  bool sessionLimitReached(SettingsController s) =>
      sessionSeconds >= s.sessionMinutes * 60;

  void grantExtraTime(int minutes) {
    bonusMinutesToday += minutes;
    sessionSeconds = 0;
    notifyListeners();
  }

  void resetAll() {
    stars = 0;
    roundsCompleted = 0;
    progress = {};
    _starKeys.clear();
    _sessionStars.clear();
    _roundAwards.clear();
    notifyListeners();
    _save();
  }

  void _load() {
    try {
      final raw = _prefs?.getString(_key);
      final legacy = raw == null ? _prefs?.getString(_legacyKey) : null;
      if (raw == null && legacy == null) return;
      final j = jsonDecode(raw ?? legacy!) as Map<String, dynamic>;
      int i(String k) => j[k] is int ? (j[k] as int).clamp(0, 1 << 30) : 0;
      // Older versions counted one "point" per right answer - those become
      // stars. Their coins, XP and badges are dropped.
      stars = raw != null ? i('stars') : i('points');
      roundsCompleted = i('rounds');
      playSecondsToday = i('playSeconds');
      usageDay = j['usageDay'] is String ? j['usageDay'] as String : '';
      final p = j['progress'];
      if (p is Map) {
        progress = {
          for (final e in p.entries) '${e.key}': GameProgress.fromJson(e.value),
        };
      }
    } catch (_) {
      // Corrupt data: start fresh rather than crash.
    }
  }

  void _save() {
    _prefs?.setString(
      _key,
      jsonEncode({
        'stars': stars,
        'rounds': roundsCompleted,
        'usageDay': usageDay,
        'playSeconds': playSecondsToday,
        'progress': progress.map((k, v) => MapEntry(k, v.toJson())),
      }),
    );
  }
}
