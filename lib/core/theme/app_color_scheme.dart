import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_palette.dart';

/// Colours with no Material slot (income green, expense red, hero card...).
/// Read with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.incomeBg,
    required this.expense,
    required this.warning,
    required this.warningBg,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroAccent,
    required this.fill,
    required this.brand,
    required this.brandBg,
  });

  final Color income;
  final Color incomeBg;
  final Color expense;
  final Color warning;
  final Color warningBg;
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  Color get onHeroSecondary => onHeroMuted;
  final Color heroAccent;

  /// Brand Orange Accent (#FF6500)
  final Color brand;
  final Color brandBg;

  /// Track behind segmented tabs, progress bars and filled inputs.
  final Color fill;

  static const light = AppColors(
    income: AppPalette.lightGreen,
    incomeBg: AppPalette.lightGreenBg,
    expense: AppPalette.lightRed,
    warning: AppPalette.lightAmber,
    warningBg: AppPalette.lightAmberBg,
    hero: AppPalette.lightHero,
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFF9AA5A0),
    heroAccent: AppPalette.brandOrange,
    fill: AppPalette.lightFill,
    brand: AppPalette.brandOrange,
    brandBg: AppPalette.brandOrangeBgLight,
  );

  static const dark = AppColors(
    income: AppPalette.darkGreen,
    incomeBg: AppPalette.darkGreenBg,
    expense: AppPalette.darkRed,
    warning: AppPalette.darkAmber,
    warningBg: AppPalette.darkAmberBg,
    hero: AppPalette.darkHero,
    onHero: AppPalette.darkInk,
    onHeroMuted: AppPalette.darkMuted,
    heroAccent: AppPalette.brandOrange,
    fill: AppPalette.darkFill,
    brand: AppPalette.brandOrange,
    brandBg: AppPalette.brandOrangeBgDark,
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      (Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light);
}

/// Builds the Material [ColorScheme] for each brightness from [AppPalette].
abstract final class AppColorScheme {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.brandOrange,
    onPrimary: Color(0xFFFFFFFF),
    secondary: AppPalette.brandOrangeDark,
    onSecondary: Color(0xFFFFFFFF),
    error: AppPalette.lightRed,
    onError: Color(0xFFFFFFFF),
    surface: AppPalette.lightCard,
    onSurface: AppPalette.lightInk,
    onSurfaceVariant: AppPalette.lightMuted,
    outlineVariant: AppPalette.lightHairline,
    outline: AppPalette.lightHairline,
    surfaceContainerHighest: AppPalette.lightFill,
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.brandOrange,
    onPrimary: Color(0xFFFFFFFF),
    secondary: AppPalette.brandOrangeLight,
    onSecondary: Color(0xFFFFFFFF),
    error: AppPalette.darkRed,
    onError: AppPalette.darkPage,
    surface: AppPalette.darkCard,
    onSurface: AppPalette.darkInk,
    onSurfaceVariant: AppPalette.darkMuted,
    outlineVariant: AppPalette.darkHairline,
    outline: AppPalette.darkHairline,
    surfaceContainerHighest: AppPalette.darkFill,
  );
}
