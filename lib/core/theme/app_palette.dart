import 'dart:ui';

/// Raw colour tokens for the Hyprwise design system. Nothing in the UI should
/// read these directly — they feed [AppColorScheme] and [AppColors] so every
/// surface maintains WCAG AA contrast (>= 4.5:1 text, >= 3:1 UI/icons).
abstract final class AppPalette {
  // Light surfaces & typography
  static const lightPage = Color(0xFFF6F6F6);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF0F0F11);
  // WCAG AA compliant on #FFFFFF (6.38:1), #F6F6F6 (5.90:1), and #EDEEED (5.48:1)
  static const lightMuted = Color(0xFF59615D);
  static const lightHairline = Color(0xFFE6E8E7);
  static const lightFill = Color(0xFFEDEEED); // tab tracks, input fills

  // Dark surfaces & typography (Obsidian canvas, zinc cards, crisp neutral hairlines)
  static const darkPage = Color(0xFF0F0F11);
  static const darkCard = Color(0xFF18181B);
  static const darkInk = Color(0xFFF4F4F6);
  // WCAG AA compliant on #18181B (6.52:1), #0F0F11 (7.05:1), and #232326 (5.75:1)
  static const darkMuted = Color(0xFF9B9BA6);
  static const darkHairline = Color(0xFF27272A);
  static const darkFill = Color(0xFF232326);

  // Hero card (deep neutral obsidian surface across light & dark themes)
  static const lightHero = Color(0xFF141417);
  static const darkHero = Color(0xFF18181C);

  // Brand Primary & Accent (Official Hyprwise Orange #FF6500 for marks/graphics)
  // Plus WCAG AA text-safe variants for foreground labels on light & dark surfaces.
  static const brandOrange = Color(0xFFFF6500);
  static const brandOrangeLight = Color(0xFFFF8533); // 7.30:1 on darkCard
  static const brandOrangeDark = Color(0xFFB84400);  // 5.45:1 on lightCard, 4.90:1 on brandOrangeBgLight
  static const brandOrangeBgLight = Color(0xFFFFF0E6);
  static const brandOrangeBgDark = Color(0xFF2E1303);

  // Semantic foregrounds & soft tinted surfaces (all WCAG AA >= 4.5:1)
  static const lightGreen = Color(0xFF1F7A45);   // 5.35:1 on white, 4.65:1 on lightGreenBg
  static const darkGreen = Color(0xFF4CC38A);    // 8.00:1 on darkCard, 6.42:1 on darkGreenBg
  static const lightRed = Color(0xFFB42318);     // 6.57:1 on white, 5.83:1 on lightRedBg
  static const darkRed = Color(0xFFF2766B);      // 6.39:1 on darkCard, 5.21:1 on darkRedBg
  static const lightAmber = Color(0xFF9A5B00);   // 5.43:1 on white, 4.86:1 on lightAmberBg
  static const darkAmber = Color(0xFFF0B24A);    // 9.43:1 on darkCard, 7.22:1 on darkAmberBg
  static const lightAmberBg = Color(0xFFFFF1D6);
  static const darkAmberBg = Color(0xFF3A2C10);
  static const lightGreenBg = Color(0xFFE3F3EA);
  static const darkGreenBg = Color(0xFF16301F);
  static const lightRedBg = Color(0xFFFDECEB);
  static const darkRedBg = Color(0xFF381918);
  static const sparkline = Color(0xFFFF6500);
}
