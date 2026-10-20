import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';
import 'settings_service.dart';

class RewardBadge {
  const RewardBadge(this.id, this.emoji, this.title);
  final String id;
  final String emoji;
  final String title;
}

const allBadges = <RewardBadge>[
  RewardBadge('first_round', '🎉', 'First Round'),
  RewardBadge('ten_rounds', '🏅', '10 Rounds'),
  RewardBadge('sorter', '🧺', 'Super Sorter'),
  RewardBadge('matcher', '🧩', 'Master Matcher'),
  RewardBadge('explorer', '🧭', 'Tried 5 Games'),
  RewardBadge('streak3', '🔥', '3 Days in a Row'),
  RewardBadge('stars50', '🌟', '50 Stars'),
];

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

class RoundReward {
  const RoundReward({
    required this.coins,
    required this.stars,
    required this.xp,
    required this.newBadges,
    required this.levelUp,
  });
  final int coins;
  final int stars;
  final int xp;
  final List<RewardBadge> newBadges;
  final Level? levelUp;
}

/// One reward service for sorting and matching. Every award is keyed by a
/// session id so replays, rebuilds or double taps can never pay twice.
/// Mistakes never remove anything.
class RewardsController extends ChangeNotifier {
  RewardsController(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _load();
  }

  static const _key = 'rewards_v1';
  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  int points = 0;
  int coins = 0;
  int stars = 0;
  int xp = 0;
  int roundsCompleted = 0;
  int sortRounds = 0;
  int matchRounds = 0;
  int dayStreak = 0;
  String lastPlayDay = '';
  String usageDay = '';
  int playSecondsToday = 0;
  Map<String, GameProgress> progress = {};
  Set<String> badges = {};

  final Set<String> _pointKeys = {};
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

  /// One point per correct action. Returns false if already awarded.
  bool awardPoint(String sessionId, String actionId) {
    if (!_pointKeys.add('$sessionId/$actionId')) return false;
    points++;
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
    if (game.kind == GameKind.sort) {
      sortRounds++;
    } else {
      matchRounds++;
    }
    const earnedCoins = 5;
    const earnedStars = 1;
    final earnedXp = correct * 2 + 5;
    coins += earnedCoins;
    stars += earnedStars;
    xp += earnedXp;
    _touchStreak();

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

    final newBadges = <RewardBadge>[];
    void check(String id, bool ok) {
      if (ok && badges.add(id)) {
        newBadges.add(allBadges.firstWhere((b) => b.id == id));
      }
    }

    check('first_round', roundsCompleted >= 1);
    check('ten_rounds', roundsCompleted >= 10);
    check('sorter', sortRounds >= 10);
    check('matcher', matchRounds >= 10);
    check('explorer', progress.values.where((p) => p.rounds > 0).length >= 5);
    check('streak3', dayStreak >= 3);
    check('stars50', stars >= 50);

    final reward = RoundReward(
      coins: earnedCoins,
      stars: earnedStars,
      xp: earnedXp,
      newBadges: newBadges,
      levelUp: levelUp,
    );
    _roundAwards[sessionId] = reward;
    notifyListeners();
    _save();
    return reward;
  }

  void _touchStreak() {
    final today = _today;
    if (lastPlayDay == today) return;
    final y = _clock().subtract(const Duration(days: 1));
    final yesterday = '${y.year}-${y.month}-${y.day}';
    dayStreak = lastPlayDay == yesterday ? dayStreak + 1 : 1;
    lastPlayDay = today;
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
    points = coins = stars = xp = 0;
    roundsCompleted = sortRounds = matchRounds = dayStreak = 0;
    lastPlayDay = '';
    progress = {};
    badges = {};
    _pointKeys.clear();
    _roundAwards.clear();
    notifyListeners();
    _save();
  }

  void _load() {
    try {
      final raw = _prefs?.getString(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      int i(String k) => j[k] is int ? (j[k] as int).clamp(0, 1 << 30) : 0;
      points = i('points');
      coins = i('coins');
      stars = i('stars');
      xp = i('xp');
      roundsCompleted = i('rounds');
      sortRounds = i('sortRounds');
      matchRounds = i('matchRounds');
      dayStreak = i('streak');
      playSecondsToday = i('playSeconds');
      lastPlayDay = j['lastDay'] is String ? j['lastDay'] as String : '';
      usageDay = j['usageDay'] is String ? j['usageDay'] as String : '';
      final p = j['progress'];
      if (p is Map) {
        progress = {
          for (final e in p.entries) '${e.key}': GameProgress.fromJson(e.value),
        };
      }
      final b = j['badges'];
      badges = b is List ? {for (final x in b) '$x'} : {};
    } catch (_) {
      // Corrupt data: start fresh rather than crash.
    }
  }

  void _save() {
    _prefs?.setString(
      _key,
      jsonEncode({
        'points': points,
        'coins': coins,
        'stars': stars,
        'xp': xp,
        'rounds': roundsCompleted,
        'sortRounds': sortRounds,
        'matchRounds': matchRounds,
        'streak': dayStreak,
        'lastDay': lastPlayDay,
        'usageDay': usageDay,
        'playSeconds': playSecondsToday,
        'progress': progress.map((k, v) => MapEntry(k, v.toJson())),
        'badges': badges.toList(),
      }),
    );
  }
}
