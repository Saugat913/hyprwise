# Finance Planner

An offline-first personal finance planner built with Flutter.

## Architecture

- Feature-first project structure.
- MVVM presentation with Flutter's native `ChangeNotifier`.
- GetIt for dependency injection.
- GoRouter for navigation.
- Drift for local SQLite persistence.
- Shared light/dark Material 3 design system.

## Local development

Use a stable Flutter SDK that satisfies the Dart SDK constraint in `pubspec.yaml`.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
flutter run
```

Drift generates `lib/core/database/app_database.g.dart` from the annotated database and table declarations. Regenerate it whenever those declarations change.

## Git workflow

- `master`: stable branch; do not develop directly on it.
- `dev`: integration branch.
- `feature/*`: short-lived feature branches created from `dev`; pull requests target `dev`.

Never target `master` with feature pull requests during active development.

## Current foundation

The initial app shell contains Home, Calendar, Money, Work and Plan destinations. These are temporary placeholders for feature implementation. Financial features will be added incrementally with domain contracts, data implementations, ViewModels and tests.

## Branding assets

- `assets/logo.svg` is the editable vector master for the brand mark.
- Export it to `assets/logo.png` before generating platform icons and native splash assets. Use a high-resolution transparent PNG; keep the mark centered with comfortable padding.
- The Flutter splash screen renders the SVG directly and shows the Finance Planner wordmark/tagline. The native splash is shown first while Flutter starts.

After adding `assets/logo.png`, generate the platform launcher icons and native splash:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The old counter demo widget test has been temporarily commented out because it referenced the removed `MyApp` counter scaffold. Tests are intentionally deferred while the app foundation is being built.
