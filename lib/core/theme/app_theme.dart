import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// Single place that turns the colour scheme into component themes.
/// Google Sans everywhere; Reddit Mono only for timers and tabular figures.
abstract final class AppTheme {
  static const sans = 'GoogleSans';
  static const mono = 'RedditMono';

  static ThemeData get light => _build(AppColorScheme.light, AppColors.light);
  static ThemeData get dark => _build(AppColorScheme.dark, AppColors.dark);

  static ThemeData _build(ColorScheme scheme, AppColors colors) {
    final text = _textTheme(scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );
    final hairline = BorderSide(color: scheme.outlineVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: sans,
      textTheme: text,
      scaffoldBackgroundColor: scheme.brightness == Brightness.light
          ? const Color(0xFFF6F6F6)
          : const Color(0xFF0F0F11),
      extensions: [colors],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: scheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: scheme.brightness,
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness: scheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: hairline,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSize.button),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: colors.fill,
          disabledForegroundColor: scheme.onSurfaceVariant,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSize.button),
          foregroundColor: scheme.onSurface,
          side: hairline,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        border: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: scheme.onSurface, width: 1.5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(scheme.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : colors.fill,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.hero,
        contentTextStyle: text.bodyMedium?.copyWith(color: colors.onHero),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      chipTheme: ChipThemeData(shape: shape),
    );
  }

  static TextTheme _textTheme(ColorScheme s) {
    TextStyle sans_(double size, FontWeight w, {double? height, Color? color}) => TextStyle(
          fontFamily: sans,
          fontSize: size,
          fontWeight: w,
          height: height,
          color: color ?? s.onSurface,
        );
    // Captions stay in Google Sans (as in the design); Reddit Mono is applied
    // explicitly via [AppTheme.figures] for timers and tabular numbers only.
    return TextTheme(
      displayLarge: sans_(44, FontWeight.w700, height: 1.05),
      displayMedium: sans_(34, FontWeight.w700, height: 1.1),
      headlineMedium: sans_(28, FontWeight.w700, height: 1.15),
      headlineSmall: sans_(26, FontWeight.w700, height: 1.15),
      titleLarge: sans_(20, FontWeight.w600),
      titleMedium: sans_(16, FontWeight.w600),
      titleSmall: sans_(14, FontWeight.w600),
      bodyLarge: sans_(16, FontWeight.w400, height: 1.4),
      bodyMedium: sans_(14, FontWeight.w400, height: 1.4),
      bodySmall: sans_(12.5, FontWeight.w400, height: 1.35, color: s.onSurfaceVariant),
      labelLarge: sans_(15, FontWeight.w600),
      labelMedium: sans_(12.5, FontWeight.w500, color: s.onSurfaceVariant),
      labelSmall: sans_(11.5, FontWeight.w500, color: s.onSurfaceVariant),
    );
  }

  /// Reddit Mono for timers and tabular figures.
  static TextStyle figures(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(fontFamily: mono, letterSpacing: -0.2);
}
