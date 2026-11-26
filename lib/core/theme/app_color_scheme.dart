import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_palette.dart';

/// Semantic colours with no Material slot (income green, expense red, hero card,
/// accessible brand text, etc.). Read via `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.incomeBg,
    required this.expense,
    required this.expenseBg,
    required this.warning,
    required this.warningBg,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroAccent,
    required this.fill,
    required this.brand,
    required this.brandText,
    required this.brandBg,
    this.liquid = const Color(0xFF22C55E),
    this.reserved = const Color(0xFF64748B),
    this.expenseBar = const Color(0xFF6B7470),
    Color? hairline,
    Color? hairlineSoft,
    Color? segmentedBg,
    Color? segmentedSelected,
    Color? textMuted,
  })  : hairline = hairline ?? const Color(0x1FFFFFFF),
        hairlineSoft = hairlineSoft ?? const Color(0x0FFFFFFF),
        segmentedBg = segmentedBg ?? const Color(0x14FFFFFF),
        segmentedSelected = segmentedSelected ?? const Color(0x2EFFFFFF),
        textMuted = textMuted ?? const Color(0xFF9CA3AF);

  final Color income;
  final Color incomeBg;
  final Color expense;
  final Color expenseBg;
  final Color warning;
  final Color warningBg;
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  Color get onHeroSecondary => onHeroMuted;
  final Color heroAccent;

  /// Brand Orange Accent (#FF6500) for brand marks, charts & icon accents.
  final Color brand;

  /// WCAG AA text-safe brand foreground (#B84400 light / #FF8533 dark).
  final Color brandText;
  final Color brandBg;

  /// Track behind segmented tabs, progress bars and filled inputs.
  final Color fill;

  /// Hero visualization & dark surface tokens.
  final Color liquid;
  final Color reserved;
  final Color expenseBar;
  final Color hairline;
  final Color hairlineSoft;
  final Color segmentedBg;
  final Color segmentedSelected;
  final Color textMuted;

  static const light = AppColors(
    income: AppPalette.lightGreen,
    incomeBg: AppPalette.lightGreenBg,
    expense: AppPalette.lightRed,
    expenseBg: AppPalette.lightRedBg,
    warning: AppPalette.lightAmber,
    warningBg: AppPalette.lightAmberBg,
    hero: AppPalette.lightHero,
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFA1A1AA),
    heroAccent: AppPalette.brandOrange,
    fill: AppPalette.lightFill,
    brand: AppPalette.brandOrange,
    brandText: AppPalette.brandOrangeDark,
    brandBg: AppPalette.brandOrangeBgLight,
    liquid: Color(0xFF22C55E),
    reserved: Color(0xFF64748B),
    expenseBar: Color(0xFF6B7470),
    hairline: Color(0x1FFFFFFF),
    hairlineSoft: Color(0x0FFFFFFF),
    segmentedBg: Color(0x14FFFFFF),
    segmentedSelected: Color(0x2EFFFFFF),
    textMuted: Color(0xFFA1A1AA),
  );

  static const dark = AppColors(
    income: AppPalette.darkGreen,
    incomeBg: AppPalette.darkGreenBg,
    expense: AppPalette.darkRed,
    expenseBg: AppPalette.darkRedBg,
    warning: AppPalette.darkAmber,
    warningBg: AppPalette.darkAmberBg,
    hero: AppPalette.darkHero,
    onHero: AppPalette.darkInk,
    onHeroMuted: AppPalette.darkMuted,
    heroAccent: AppPalette.brandOrange,
    fill: AppPalette.darkFill,
    brand: AppPalette.brandOrange,
    brandText: AppPalette.brandOrangeLight,
    brandBg: AppPalette.brandOrangeBgDark,
    liquid: Color(0xFF22C55E),
    reserved: Color(0xFF64748B),
    expenseBar: Color(0xFF8A938E),
    hairline: Color(0x1FFFFFFF),
    hairlineSoft: Color(0x0FFFFFFF),
    segmentedBg: Color(0x14FFFFFF),
    segmentedSelected: Color(0x2EFFFFFF),
    textMuted: AppPalette.darkMuted,
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t) ?? income,
      incomeBg: Color.lerp(incomeBg, other.incomeBg, t) ?? incomeBg,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      expenseBg: Color.lerp(expenseBg, other.expenseBg, t) ?? expenseBg,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningBg: Color.lerp(warningBg, other.warningBg, t) ?? warningBg,
      hero: Color.lerp(hero, other.hero, t) ?? hero,
      onHero: Color.lerp(onHero, other.onHero, t) ?? onHero,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t) ?? onHeroMuted,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t) ?? heroAccent,
      fill: Color.lerp(fill, other.fill, t) ?? fill,
      brand: Color.lerp(brand, other.brand, t) ?? brand,
      brandText: Color.lerp(brandText, other.brandText, t) ?? brandText,
      brandBg: Color.lerp(brandBg, other.brandBg, t) ?? brandBg,
      liquid: Color.lerp(liquid, other.liquid, t) ?? liquid,
      reserved: Color.lerp(reserved, other.reserved, t) ?? reserved,
      expenseBar: Color.lerp(expenseBar, other.expenseBar, t) ?? expenseBar,
      hairline: Color.lerp(hairline, other.hairline, t) ?? hairline,
      hairlineSoft: Color.lerp(hairlineSoft, other.hairlineSoft, t) ?? hairlineSoft,
      segmentedBg: Color.lerp(segmentedBg, other.segmentedBg, t) ?? segmentedBg,
      segmentedSelected: Color.lerp(segmentedSelected, other.segmentedSelected, t) ?? segmentedSelected,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
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
    primary: AppPalette.lightInk,
    onPrimary: Color(0xFFFFFFFF),
    secondary: AppPalette.brandOrange,
    onSecondary: AppPalette.lightInk, // 6.49:1 WCAG AA (white on #FF6500 was 2.95:1)
    tertiary: AppPalette.brandOrangeDark,
    onTertiary: Color(0xFFFFFFFF), // 5.45:1 WCAG AA
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
    primary: AppPalette.darkInk,
    onPrimary: AppPalette.darkPage,
    secondary: AppPalette.brandOrange,
    onSecondary: AppPalette.darkPage, // 6.49:1 WCAG AA
    tertiary: AppPalette.brandOrangeLight,
    onTertiary: AppPalette.darkPage,  // 8.21:1 WCAG AA
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
