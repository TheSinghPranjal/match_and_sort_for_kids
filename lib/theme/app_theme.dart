import 'package:flutter/material.dart';

/// Bright, candy-coloured palette used across the whole app.
///
/// Surfaces are slightly desaturated pastels (claymorphism), while the
/// saturated "pop" colours are reserved for calls to action and targets.
class AppColors {
  AppColors._();

  static const sky = Color(0xFF8ED6FF);
  static const skyDeep = Color(0xFF4FB3F6);
  static const mint = Color(0xFF7FE3C4);
  static const mintDeep = Color(0xFF2EC4A0);
  static const coral = Color(0xFFFF8A7A);
  static const coralDeep = Color(0xFFFF5E62);
  static const peach = Color(0xFFFFC29E);
  static const lavender = Color(0xFFC4B2FF);
  static const lavenderDeep = Color(0xFF8C6CF2);
  static const cream = Color(0xFFFFF7E8);
  static const sunny = Color(0xFFFFD95A);
  static const sunnyDeep = Color(0xFFFFB627);
  static const bubblegum = Color(0xFFFF9ED2);
  static const grass = Color(0xFF8EDB6A);
  static const grassDeep = Color(0xFF55B948);

  /// Deep plum ink: high contrast on every pastel surface.
  static const ink = Color(0xFF3A2559);
  static const inkSoft = Color(0xFF6B5A86);

  /// Rotating funky card colours for catalog tiles.
  static const cardPalette = <Color>[
    coral,
    sky,
    sunny,
    mint,
    lavender,
    bubblegum,
    peach,
    grass,
  ];

  static Color darken(Color c, [double amount = 0.18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color lighten(Color c, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Typography. Fredoka (chunky, rounded) for headings and buttons,
/// Nunito (rounded terminals) for body copy. Both are variable fonts, so the
/// weight is applied through the `wght` axis.
class AppText {
  AppText._();

  static TextStyle display(double size, {Color color = AppColors.ink}) =>
      _fredoka(size, 650, color);

  static TextStyle title(double size, {Color color = AppColors.ink}) =>
      _fredoka(size, 600, color);

  static TextStyle button(double size, {Color color = Colors.white}) =>
      _fredoka(size, 600, color);

  static TextStyle body(
    double size, {
    Color color = AppColors.ink,
    double weight = 700,
  }) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    color: color,
    height: 1.25,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation('wght', weight)],
  );

  static TextStyle _fredoka(double size, double weight, Color color) =>
      TextStyle(
        fontFamily: 'Fredoka',
        fontSize: size,
        color: color,
        height: 1.1,
        fontWeight: _weight(weight),
        fontVariations: [FontVariation('wght', weight)],
      );

  static FontWeight _weight(double w) =>
      FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.skyDeep,
      primary: AppColors.skyDeep,
      secondary: AppColors.coral,
      surface: AppColors.cream,
    ),
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: AppColors.sky,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.mintDeep : null,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.lavenderDeep,
      thumbColor: AppColors.lavenderDeep,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
