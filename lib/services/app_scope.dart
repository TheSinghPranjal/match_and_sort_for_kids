import 'package:flutter/widgets.dart';

import 'audio_service.dart';
import 'rewards_service.dart';
import 'settings_service.dart';

/// Makes the app-wide services available to every screen. Widgets that
/// need to rebuild on change wrap themselves in a ListenableBuilder.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.rewards,
    required this.audio,
    required super.child,
  });

  final SettingsController settings;
  final RewardsController rewards;
  final AudioService audio;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above $context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      settings != old.settings || rewards != old.rewards || audio != old.audio;
}
