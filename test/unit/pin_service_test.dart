import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_break/core/services/pin_service.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PinService pinService;
  late DateTime simulatedTime;

  DateTime getClock() => simulatedTime;

  setUp(() async {
    final db = await setupTestDatabase();
    simulatedTime = DateTime(2026, 10, 20, 10, 0, 0);
    pinService = PinService(db: db, clock: getClock);
  });

  group('PinService Tests', () {
    test('generateSecurePin produces exactly 8 numeric digits', () {
      final pin = PinService.generateSecurePin();
      expect(pin.length, 8);
      expect(int.tryParse(pin), isNotNull);
    });

    test('PIN is string preserving potential leading zeros', () {
      for (int i = 0; i < 50; i++) {
        final pin = PinService.generateSecurePin();
        expect(pin, isA<String>());
        expect(pin.length, 8);
        expect(RegExp(r'^\d{8}$').hasMatch(pin), isTrue);
      }
    });

    test('PIN maintains 24-hour validity window with deterministic clock', () async {
      final state1 = await pinService.getCurrentPinState();
      expect(state1.currentPin.length, 8);
      expect(state1.windowStart, simulatedTime);
      expect(state1.windowExpires, simulatedTime.add(const Duration(hours: 24)));

      // Advance clock by 12 hours (within 24-hour window)
      simulatedTime = simulatedTime.add(const Duration(hours: 12));
      final state2 = await pinService.getCurrentPinState();
      // Should remain the same PIN
      expect(state2.currentPin, state1.currentPin);

      // Advance clock beyond 24 hours
      simulatedTime = simulatedTime.add(const Duration(hours: 13)); // Total 25 hours elapsed
      final state3 = await pinService.getCurrentPinState();
      // Should have generated new PIN for new 24h window
      expect(state3.windowStart, simulatedTime);
      expect(state3.windowExpires, simulatedTime.add(const Duration(hours: 24)));
    });

    test('validatePin validates matching PIN and rejects incorrect PIN', () async {
      final state = await pinService.getCurrentPinState();
      final valid = await pinService.validatePin(state.currentPin);
      expect(valid, isTrue);

      final invalid = await pinService.validatePin('99999999');
      // If 99999999 happened to match by 1-in-100-million chance:
      if (state.currentPin != '99999999') {
        expect(invalid, isFalse);
      }
    });

    test('Repeated failures trigger rate-limiting lockout', () async {
      await pinService.getCurrentPinState();

      expect(pinService.isLockedOut(), isFalse);

      // Fail 5 times with incorrect PIN
      for (int i = 0; i < 5; i++) {
        await pinService.validatePin('00000000');
      }

      expect(pinService.isLockedOut(), isTrue);
      expect(pinService.getRemainingLockout().inSeconds, greaterThan(0));

      // Advance clock past 30-second lockout
      simulatedTime = simulatedTime.add(const Duration(seconds: 35));
      expect(pinService.isLockedOut(), isFalse);
    });

    test('rotatePinNow forces immediate PIN rotation', () async {
      final state1 = await pinService.getCurrentPinState();
      final state2 = await pinService.rotatePinNow();

      expect(state1.currentPin, isNotEmpty);
      expect(state2.windowStart, simulatedTime);
      expect(state2.windowExpires, simulatedTime.add(const Duration(hours: 24)));
    });
  });
}
