import 'dart:ui';

/// Raw colour tokens sampled from the "Finance Planner" design. Nothing in the
/// UI reads these directly: they feed `AppColorScheme`, and widgets read the
/// resulting `ColorScheme` / `AppColors`. Swapping a token re-themes the app.
abstract final class AppPalette {
  // Light
  static const lightPage = Color(0xFFF6F6F6);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF0F0F11);
  static const lightMuted = Color(0xFF7A827E);
  static const lightHairline = Color(0xFFE6E8E7);
  static const lightFill = Color(0xFFEDEEED); // tab tracks, input fills

  // Dark (Neutral modern dark palette: pure obsidian, slate cards, neutral grey borders)
  static const darkPage = Color(0xFF0F0F11);
  static const darkCard = Color(0xFF18181B);
  static const darkInk = Color(0xFFF4F4F6);
  static const darkMuted = Color(0xFF8F8F99);
  static const darkHairline = Color(0xFF27272A);
  static const darkFill = Color(0xFF232326);

  // Hero card (the sleek neutral deep surface with subtle depth)
  static const lightHero = Color(0xFF141417);
  static const darkHero = Color(0xFF18181C);

  // Brand Primary & Accent (Official Hyprwise Orange #FF6500)
  static const brandOrange = Color(0xFFFF6500);
  static const brandOrangeLight = Color(0xFFFF8533);
  static const brandOrangeDark = Color(0xFFE05800);
  static const brandOrangeBgLight = Color(0xFFFFF0E6);
  static const brandOrangeBgDark = Color(0xFF2E1303);

  // Semantic
  static const lightGreen = Color(0xFF1F7A45);
  static const darkGreen = Color(0xFF4CC38A);
  static const lightRed = Color(0xFFB42318);
  static const darkRed = Color(0xFFF2766B);
  static const lightAmber = Color(0xFF9A5B00);
  static const darkAmber = Color(0xFFF0B24A);
  static const lightAmberBg = Color(0xFFFFF1D6);
  static const darkAmberBg = Color(0xFF3A2C10);
  static const lightGreenBg = Color(0xFFE3F3EA);
  static const darkGreenBg = Color(0xFF16301F);
  static const sparkline = Color(0xFFFF6500);
}
