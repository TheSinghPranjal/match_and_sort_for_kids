import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_and_sort_for_kids/data/themes.dart';
import 'package:match_and_sort_for_kids/main.dart';
import 'package:match_and_sort_for_kids/screens/home_screen.dart';
import 'package:match_and_sort_for_kids/screens/splash_screen.dart';
import 'package:match_and_sort_for_kids/services/audio_service.dart';
import 'package:match_and_sort_for_kids/services/rewards_service.dart';
import 'package:match_and_sort_for_kids/services/settings_service.dart';
import 'package:match_and_sort_for_kids/theme/app_theme.dart';
import 'package:match_and_sort_for_kids/widgets/clay.dart';
import 'package:match_and_sort_for_kids/widgets/garden_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

Future<void> _pumpSplash(
  WidgetTester tester, {
  required Size size,
  ThemeData? theme,
  double textScale = 1,
  Duration duration = const Duration(days: 1),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? buildAppTheme(),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
      home: SplashScreen(duration: duration),
    ),
  );
  // Let the entrance fade finish so semantics are exposed.
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('splash shows the app name and studio byline', (tester) async {
    await _pumpSplash(tester, size: const Size(390, 844));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Match & Sort', findRichText: true), findsWidgets);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(find.bySemanticsLabel('Match & Sort'), findsOneWidget);
    expect(find.bySemanticsLabel('by The Lazy Bear Club'), findsOneWidget);

    final logo = tester.widget<Image>(find.byKey(kLazyBearClubLogoKey));
    expect(logo.image, isA<AssetImage>());
    expect((logo.image as AssetImage).assetName, kLazyBearClubAsset);

    final by = tester.widget<Text>(find.text('by'));
    final name = tester.widget<Text>(find.text('The Lazy Bear Club'));
    expect(by.style?.color, AppColors.ink);
    expect(name.style?.color, AppColors.ink);
    expect(
      tester
          .widgetList<ClayContainer>(find.byType(ClayContainer))
          .any((c) => c.color == AppColors.cream),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('splash fades into the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(prefs)
      ..update((s) => s.reducedMotion = true);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MatchAndSortApp(
        settings: settings,
        rewards: RewardsController(prefs),
        audio: SilentAudio(),
      ),
    );
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);

    await tester.pump(kSplashDuration + const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsNothing);
    expect(find.text('Colour Sorting'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  for (final size in const <Size>[
    Size(320, 568),
    Size(320, 480),
    Size(375, 667),
    Size(390, 844),
    Size(667, 375),
    Size(768, 1024),
    Size(1024, 768),
  ]) {
    testWidgets('splash fits ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      await _pumpSplash(tester, size: size, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('The Lazy Bear Club'), findsOneWidget);
      expect(find.text('by'), findsOneWidget);
      await _dispose(tester);
    });
  }

  testWidgets('splash byline stays readable in a dark theme', (tester) async {
    await _pumpSplash(
      tester,
      size: const Size(390, 844),
      textScale: 1.3,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
    );

    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    final by = tester.widget<Text>(find.text('by'));
    final name = tester.widget<Text>(find.text('The Lazy Bear Club'));
    expect(by.style?.color, AppColors.ink);
    expect(name.style?.color, AppColors.ink);
    expect(
      tester.widget<GardenBackground>(find.byType(GardenBackground)).theme.top,
      isNot(Themes.garden.top),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 568) * 3;
    await tester.pump();
    tester.view.physicalSize = const Size(1024, 768) * 3;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });
}
