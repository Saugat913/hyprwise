import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/auth/view/login_screen.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SettingsRepository settingsRepo;
  late AuthService authService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settingsRepo = SettingsRepository(db);
    await settingsRepo.load();
    authService = AuthService();

    if (getIt.isRegistered<SettingsRepository>()) {
      getIt.unregister<SettingsRepository>();
    }
    if (getIt.isRegistered<AuthService>()) {
      getIt.unregister<AuthService>();
    }
    getIt.registerSingleton<SettingsRepository>(settingsRepo);
    getIt.registerSingleton<AuthService>(authService);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('LoginScreen renders decluttered brand elements, official buttons, and handles legal dialogs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Hyprwise brand title and buttons (on Android, Apple login is hidden)
    expect(find.text('hyprwise'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue as Guest (Offline)'), findsOneWidget);

    // Verify SVG logos are rendered
    expect(find.byType(SvgPicture), findsWidgets);

    // Verify clutter is removed (no language toggle and no feature pills on LoginScreen)
    expect(find.text('English'), findsNothing);
    expect(find.text('On-Device Secure'), findsNothing);
    expect(find.text('Live Shifts'), findsNothing);
    expect(find.text('Financial Pulse'), findsNothing);

    // Tap Terms of Service to verify dialog opens
    final termsButton = find.text('Terms of Service');
    expect(termsButton, findsOneWidget);
    await tester.tap(termsButton);
    await tester.pumpAndSettle();

    expect(find.text('Got it'), findsOneWidget);
    // Dismiss dialog
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    // Tap Privacy Policy to verify dialog opens
    final privacyButton = find.text('Privacy Policy');
    expect(privacyButton, findsOneWidget);
    await tester.tap(privacyButton);
    await tester.pumpAndSettle();

    expect(find.text('Got it'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
  });
}
