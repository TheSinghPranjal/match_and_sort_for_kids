import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings_service.dart';

enum Sfx { pop, correct, tryAgain, match, celebrate }

/// Sound effects, spoken words and haptics. Each is controlled by its own
/// parent setting, and every game remains fully playable in silence.
abstract class AudioService {
  void sfx(Sfx s);
  void speak(String text);
  void haptic({bool strong = false});
  void stop();
}

class DeviceAudio implements AudioService {
  DeviceAudio(this._settings);

  final SettingsController _settings;
  final Map<Sfx, AudioPlayer> _players = {};
  FlutterTts? _tts;

  static const _files = {
    Sfx.pop: 'sounds/pop.wav',
    Sfx.correct: 'sounds/correct.wav',
    Sfx.tryAgain: 'sounds/try_again.wav',
    Sfx.match: 'sounds/match.wav',
    Sfx.celebrate: 'sounds/celebrate.wav',
  };

  @override
  void sfx(Sfx s) {
    if (!_settings.soundEffects) return;
    try {
      final p = _players.putIfAbsent(s, () {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        player.setVolume(s == Sfx.tryAgain ? 0.35 : 0.6);
        return player;
      });
      p.stop().then((_) => p.play(AssetSource(_files[s]!))).catchError((_) {});
    } catch (_) {
      // Audio is a nice-to-have; never let it interrupt play.
    }
  }

  @override
  void speak(String text) {
    if (!_settings.voice || text.isEmpty) return;
    try {
      final tts = _tts ??= FlutterTts()
        ..setSpeechRate(0.42)
        ..setPitch(1.15);
      tts.stop().then((_) => tts.speak(text)).catchError((_) {});
    } catch (_) {}
  }

  @override
  void haptic({bool strong = false}) {
    if (!_settings.haptics) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
  }

  @override
  void stop() {
    try {
      _tts?.stop();
    } catch (_) {}
  }
}

/// No-op implementation for tests.
class SilentAudio implements AudioService {
  final List<Object> log = [];
  @override
  void sfx(Sfx s) => log.add(s);
  @override
  void speak(String text) => log.add(text);
  @override
  void haptic({bool strong = false}) {}
  @override
  void stop() {}
}
