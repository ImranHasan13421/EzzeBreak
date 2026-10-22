import 'dart:math';
import '../database/app_database.dart';
import '../../shared/models/pin_state.dart';

class PinService {
  final AppDatabase _db;
  final DateTime Function() _clock;

  PinState? _cachedPinState;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  PinService({
    AppDatabase? db,
    DateTime Function()? clock,
  })  : _db = db ?? AppDatabase.instance,
        _clock = clock ?? DateTime.now;

  /// Generates a cryptographically secure 8-digit PIN string (e.g. "04829103")
  static String generateSecurePin() {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buffer.write(random.nextInt(10));
    }
    return buffer.toString();
  }

  /// Gets the current valid PIN state, rotating if the 24-hour window has expired.
  Future<PinState> getCurrentPinState() async {
    final now = _clock();

    if (_cachedPinState != null && !_cachedPinState!.isExpired(now)) {
      return _cachedPinState!;
    }

    final fromDb = await _db.getPinState();
    if (fromDb != null && !fromDb.isExpired(now)) {
      _cachedPinState = fromDb;
      return fromDb;
    }

    // Window has expired or no PIN exists: generate new 8-digit PIN expiring at 12:00 AM midnight
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final newPin = generateSecurePin();
    final newPinState = PinState(
      currentPin: newPin,
      windowStart: now,
      windowExpires: nextMidnight,
      updatedAt: now,
    );

    await _db.savePinState(newPinState);
    _cachedPinState = newPinState;
    return newPinState;
  }

  /// Checks if PIN entry is temporarily rate-limited
  bool isLockedOut() {
    final now = _clock();
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      return true;
    }
    if (_lockoutUntil != null && !now.isBefore(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
    }
    return false;
  }

  Duration getRemainingLockout() {
    final now = _clock();
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      return _lockoutUntil!.difference(now);
    }
    return Duration.zero;
  }

  /// Validates user-entered PIN against the current active PIN
  Future<bool> validatePin(String inputPin) async {
    if (isLockedOut()) {
      return false;
    }

    final pinState = await getCurrentPinState();
    final isMatch = pinState.currentPin == inputPin.trim();

    if (isMatch) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        // 30 seconds rate-limit cooldown
        _lockoutUntil = _clock().add(const Duration(seconds: 30));
      }
      return false;
    }
  }

  /// Force-rotates the PIN (for testing or user reset with confirmation)
  Future<PinState> rotatePinNow() async {
    final now = _clock();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final newPin = generateSecurePin();
    final newPinState = PinState(
      currentPin: newPin,
      windowStart: now,
      windowExpires: nextMidnight,
      updatedAt: now,
    );

    await _db.savePinState(newPinState);
    _cachedPinState = newPinState;
    _failedAttempts = 0;
    _lockoutUntil = null;
    return newPinState;
  }
}
