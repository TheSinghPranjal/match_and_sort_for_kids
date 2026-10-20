import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'services/app_scope.dart';
import 'services/audio_service.dart';
import 'services/rewards_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // Storage unavailable: play with defaults, nothing persists.
  }
  final settings = SettingsController(prefs);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(
    MatchAndSortApp(
      settings: settings,
      rewards: RewardsController(prefs),
      audio: DeviceAudio(settings),
    ),
  );
}

class MatchAndSortApp extends StatelessWidget {
  const MatchAndSortApp({
    super.key,
    required this.settings,
    required this.rewards,
    required this.audio,
  });

  final SettingsController settings;
  final RewardsController rewards;
  final AudioService audio;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: settings,
      rewards: rewards,
      audio: audio,
      child: MaterialApp(
        title: 'Match & Sort',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        builder: (context, child) {
          // Keep text from growing past what the layouts can hold.
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
            ),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
