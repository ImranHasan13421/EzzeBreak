import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezze_break/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ezze_break/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ezze_break/features/overrides/presentation/override_dialog.dart';
import 'package:ezze_break/features/pin_management/presentation/pin_entry_screen.dart';
import 'package:ezze_break/features/pin_management/presentation/show_pin_screen.dart';
import 'package:ezze_break/features/settings/providers/theme_provider.dart';
import 'package:ezze_break/core/services/usage_monitor_service.dart';
import 'package:ezze_break/shared/models/monitored_app.dart';
import 'package:ezze_break/shared/models/pin_state.dart';
import 'package:ezze_break/features/monitoring/providers/monitoring_providers.dart';
import 'package:ezze_break/features/splash/presentation/splash_screen.dart';
import 'test_helper.dart';

class FakePinStateNotifier extends StateNotifier<AsyncValue<PinState>> implements PinStateNotifier {
  FakePinStateNotifier(PinState pinState) : super(AsyncValue.data(pinState));

  @override
  Future<void> loadPin() async {}

  @override
  Future<void> rotatePin() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    await setupTestDatabase();
    SharedPreferences.setMockInitialValues({
      'ezze_onboarding_completed': true,
      'ezze_display_name': 'Test User',
    });
    prefs = await SharedPreferences.getInstance();
    UsageMonitorService.instance.stop();
  });

  tearDown(() {
    UsageMonitorService.instance.stop();
  });

  Widget createTestWidget(Widget child, [List<Override> overrides = const []]) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Widget Tests', () {
    testWidgets('SplashScreen displays logo, brand, and tagline', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SplashScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('EZZE BREAK'), findsOneWidget);
      expect(find.text('Use mindfully. Move regularly. Feel better.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 11));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('OnboardingScreen renders title and navigation buttons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          OnboardingScreen(onFinish: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EZZE BREAK'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('How Ezze Break Works'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('DashboardScreen displays header and quick actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          const DashboardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 11));

      expect(find.text('EZZE BREAK'), findsOneWidget);
      expect(find.text('Hello, Test User'), findsOneWidget);
      expect(find.text('Daily Screen Budget'), findsOneWidget);
      expect(find.text('Add App'), findsOneWidget);
      expect(find.text('Daily PIN'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('PinEntryScreen displays 8 digit boxes and keypad', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PinEntryScreen(
            title: 'Enter 8-Digit PIN',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter 8-Digit PIN'), findsOneWidget);
      // Keypad digits 0-9
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Enter digits
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();

      expect(find.text('1'), findsNWidgets(2)); // Keypad + 1 box
      expect(find.text('2'), findsNWidgets(2)); // Keypad + 1 box
    });

    testWidgets('ShowPinScreen displays PIN information card', (tester) async {
      final now = DateTime.now();
      final pinState = PinState(
        currentPin: '12345678',
        windowStart: now,
        windowExpires: now.add(const Duration(hours: 24)),
        updatedAt: now,
      );

      await tester.pumpWidget(
        createTestWidget(
          const ShowPinScreen(),
          [
            pinStateNotifierProvider.overrideWith((ref) => FakePinStateNotifier(pinState)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Today\'s 8-Digit PIN'), findsOneWidget);
      expect(find.textContaining('Valid until midnight'), findsOneWidget);
      expect(find.text('Copy PIN to Clipboard'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('OverrideDialog displays warning and extension buttons', (tester) async {
      final app = MonitoredApp(
        packageName: 'com.social.media',
        appName: 'Social Media',
      );

      await tester.pumpWidget(
        createTestWidget(
          OverrideDialog(
            app: app,
            usageSeconds: 3600,
            budgetMinutes: 60,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Override Social Media'), findsOneWidget);
      expect(find.text('Current Usage'), findsOneWidget);
      expect(find.text('Daily Budget'), findsOneWidget);
      expect(find.text('Override Duration'), findsOneWidget);
      expect(find.text('Enter PIN →'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
