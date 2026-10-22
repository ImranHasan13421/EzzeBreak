import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezze_break/features/settings/presentation/settings_screen.dart';
import 'package:ezze_break/features/settings/providers/theme_provider.dart';
import 'package:ezze_break/features/monitoring/providers/monitoring_providers.dart';
import 'package:ezze_break/app/theme/app_theme.dart';
import 'test_helper.dart';

class FakeIncompletePermissionsNotifier extends StateNotifier<PermissionsState> implements PermissionsNotifier {
  FakeIncompletePermissionsNotifier()
      : super(const PermissionsState(
          hasUsageAccess: false,
          hasOverlay: false,
          hasAccessibility: false,
          hasNotification: false,
        ));

  @override
  Future<void> checkAll() async {
    // Keep them false for test
    state = const PermissionsState(
      hasUsageAccess: false,
      hasOverlay: false,
      hasAccessibility: false,
      hasNotification: false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    await setupTestDatabase();
    SharedPreferences.setMockInitialValues({
      'ezze_onboarding_completed': true,
      'ezze_display_name': 'Test User',
      'ezze_theme_mode': 'dark',
    });
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('SettingsScreen mobile viewport test with incomplete permissions renders without overflow', (tester) async {
    // Standard 360dp mobile screen (1080x2400 @ 3.0 dpr)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          permissionsProvider.overrideWith((ref) => FakeIncompletePermissionsNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('System Permissions'), findsOneWidget);
    expect(find.text('Usage Access'), findsOneWidget);
    expect(find.text('Display Over Other Apps'), findsOneWidget);
    expect(find.text('Accessibility Service'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);

    // Verify all 4 Required badges and 4 Grant Permission buttons render cleanly
    expect(find.text('Required'), findsNWidgets(4));
    expect(find.text('Grant Permission'), findsNWidgets(4));

    // Verify no render flex errors or unhandled exceptions occurred
    expect(tester.takeException(), isNull);
  });
}
