import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Maps raw palette colors to Material semantic color roles.
abstract final class AppColors {
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.brand,
    onPrimary: AppPalette.brandOn,
    primaryContainer: AppPalette.brandSubtle,
    onPrimaryContainer: AppPalette.brandPressed,
    secondary: AppPalette.neutral700,
    onSecondary: AppPalette.white,
    secondaryContainer: AppPalette.neutral100,
    onSecondaryContainer: AppPalette.neutral900,
    tertiary: AppPalette.info,
    onTertiary: AppPalette.white,
    tertiaryContainer: AppPalette.infoSubtle,
    onTertiaryContainer: AppPalette.neutral900,
    error: AppPalette.expense,
    onError: AppPalette.white,
    errorContainer: AppPalette.expenseSubtle,
    onErrorContainer: AppPalette.expense,
    surface: AppPalette.white,
    onSurface: AppPalette.neutral900,
    surfaceDim: AppPalette.neutral200,
    surfaceBright: AppPalette.white,
    surfaceContainerLowest: AppPalette.white,
    surfaceContainerLow: AppPalette.neutral50,
    surfaceContainer: AppPalette.neutral100,
    surfaceContainerHigh: AppPalette.neutral100,
    surfaceContainerHighest: AppPalette.neutral200,
    onSurfaceVariant: AppPalette.neutral600,
    outline: AppPalette.neutral400,
    outlineVariant: AppPalette.neutral200,
    shadow: AppPalette.black,
    scrim: AppPalette.scrim,
    inverseSurface: AppPalette.neutral900,
    onInverseSurface: AppPalette.neutral50,
    inversePrimary: AppPalette.brandLight,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.brandLight,
    onPrimary: AppPalette.neutral950,
    primaryContainer: AppPalette.brandContainerDark,
    onPrimaryContainer: AppPalette.brandOnContainerDark,
    secondary: AppPalette.neutral300,
    onSecondary: AppPalette.neutral950,
    secondaryContainer: AppPalette.neutral800,
    onSecondaryContainer: AppPalette.neutral100,
    tertiary: AppPalette.infoLight,
    onTertiary: AppPalette.neutral950,
    tertiaryContainer: AppPalette.infoContainerDark,
    onTertiaryContainer: AppPalette.infoOnContainerDark,
    error: AppPalette.expenseLight,
    onError: AppPalette.neutral950,
    errorContainer: AppPalette.expenseContainerDark,
    onErrorContainer: AppPalette.expenseOnContainerDark,
    surface: AppPalette.neutral950,
    onSurface: AppPalette.neutral100,
    surfaceDim: AppPalette.black,
    surfaceBright: AppPalette.neutral800,
    surfaceContainerLowest: AppPalette.black,
    surfaceContainerLow: AppPalette.neutral950,
    surfaceContainer: AppPalette.neutral900,
    surfaceContainerHigh: AppPalette.neutral800,
    surfaceContainerHighest: AppPalette.neutral700,
    onSurfaceVariant: AppPalette.neutral300,
    outline: AppPalette.neutral600,
    outlineVariant: AppPalette.neutral800,
    shadow: AppPalette.black,
    scrim: AppPalette.scrim,
    inverseSurface: AppPalette.neutral100,
    onInverseSurface: AppPalette.neutral900,
    inversePrimary: AppPalette.brand,
  );

  // Extra semantic colors not represented directly by ColorScheme.
  static const Color income = AppPalette.income;
  static const Color incomeSubtle = AppPalette.incomeSubtle;
  static const Color expense = AppPalette.expense;
  static const Color expenseSubtle = AppPalette.expenseSubtle;
  static const Color warning = AppPalette.warning;
  static const Color warningSubtle = AppPalette.warningSubtle;
  static const Color info = AppPalette.info;
  static const Color infoSubtle = AppPalette.infoSubtle;
  static const Color success = AppPalette.success;
  static const Color successSubtle = AppPalette.successSubtle;
}
