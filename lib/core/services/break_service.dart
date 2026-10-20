import '../database/app_database.dart';
import '../../shared/models/break_session.dart';
import '../../shared/models/exercise_log.dart';
import 'pin_service.dart';

class BreakService {
  final AppDatabase _db;
  final PinService _pinService;
  final DateTime Function() _clock;

  BreakService({
    AppDatabase? db,
    PinService? pinService,
    DateTime Function()? clock,
  })  : _db = db ?? AppDatabase.instance,
        _pinService = pinService ?? PinService(),
        _clock = clock ?? DateTime.now;

  /// Starts or retrieves an active break session for a monitored app
  Future<BreakSession> requireBreak({
    required String packageName,
    required int breakDurationSeconds,
  }) async {
    final existing = await _db.getActiveBreakSession(packageName);
    if (existing != null) {
      return existing;
    }

    final now = _clock();
    final newSession = BreakSession(
      id: '${packageName}_${now.millisecondsSinceEpoch}',
      packageName: packageName,
      triggerTime: now,
      requiredBreakSeconds: breakDurationSeconds,
      currentState: BreakState.breakRequired,
    );

    await _db.createBreakSession(newSession);
    return newSession;
  }

  /// Transition: breakRequired -> breakInProgress
  Future<BreakSession> startBreakTimer(BreakSession session) async {
    final updated = session.copyWith(
      currentState: BreakState.breakInProgress,
    );
    await _db.updateBreakSession(updated);
    return updated;
  }

  /// Transition: breakInProgress -> exerciseInProgress
  Future<BreakSession> startExercises(BreakSession session) async {
    final updated = session.copyWith(
      currentState: BreakState.exerciseInProgress,
    );
    await _db.updateBreakSession(updated);
    return updated;
  }

  /// Transition: exerciseInProgress -> awaitingPin
  Future<BreakSession> completeExercises(BreakSession session, List<ExerciseLog> logs) async {
    for (final log in logs) {
      await _db.logExercise(log);
    }

    final updated = session.copyWith(
      currentState: BreakState.awaitingPin,
    );
    await _db.updateBreakSession(updated);
    return updated;
  }

  /// Validates PIN and transitions: awaitingPin -> eligibleToResume
  Future<bool> validateAndUnlockBreak(BreakSession session, String pin) async {
    final isValid = await _pinService.validatePin(pin);
    if (!isValid) return false;

    final now = _clock();
    final completed = session.copyWith(
      currentState: BreakState.eligibleToResume,
      completedTime: now,
      pinValidated: true,
    );

    await _db.updateBreakSession(completed);
    return true;
  }

  /// Invalidates or cancels a break session
  Future<void> cancelBreak(BreakSession session) async {
    final cancelled = session.copyWith(
      currentState: BreakState.cancelledOrInvalidated,
    );
    await _db.updateBreakSession(cancelled);
  }

  /// Gets currently active break for a package
  Future<BreakSession?> getActiveBreak(String packageName) async {
    return await _db.getActiveBreakSession(packageName);
  }
}
