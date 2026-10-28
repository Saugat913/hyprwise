/// Spacing, radii and fixed sizes. The only place layout numbers are defined.
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal padding of every page.
  static const double page = 20;
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;
}

abstract final class AppSize {
  static const double button = 56;
  static const double input = 52;
  static const double iconBox = 40;
  static const double avatar = 44;
  static const double navBar = 72;
  static const double progressStep = 3;
}

/// Backward compatibility class for presentation layers referencing legacy dimensions.
abstract final class AppDimensions {
  static const double pageMaxWidth = 720;
  static const double screenPadding = AppSpace.page;
  static const double radiusCard = AppRadius.md;
  static const double cardPadding = AppSpace.lg;
  static const double spaceXs = AppSpace.xs;
  static const double spaceSm = AppSpace.sm;
  static const double spaceMd = AppSpace.md;
  static const double spaceLg = AppSpace.lg;
  static const double spaceXl = AppSpace.xl;
  static const double spaceXxl = AppSpace.xxl;
  static const double spaceXxxl = AppSpace.xxxl;
}
