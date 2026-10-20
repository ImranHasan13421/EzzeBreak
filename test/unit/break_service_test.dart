import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_break/core/services/break_service.dart';
import 'package:ezze_break/core/services/pin_service.dart';
import 'package:ezze_break/shared/models/break_session.dart';
import 'package:ezze_break/shared/models/exercise_log.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BreakService breakService;
  late PinService pinService;
  late DateTime simulatedTime;

  DateTime getClock() => simulatedTime;

  setUp(() async {
    final db = await setupTestDatabase();
    simulatedTime = DateTime(2026, 10, 20, 10, 0, 0);
    pinService = PinService(db: db, clock: getClock);
    breakService = BreakService(db: db, pinService: pinService, clock: getClock);
  });

  group('BreakService State Machine Tests', () {
    test('requireBreak creates session in breakRequired state', () async {
      final session = await breakService.requireBreak(
        packageName: 'com.example.social',
        breakDurationSeconds: 300,
      );

      expect(session.packageName, 'com.example.social');
      expect(session.currentState, BreakState.breakRequired);
      expect(session.requiredBreakSeconds, 300);
      expect(session.pinValidated, isFalse);
    });

    test('startBreakTimer transitions to breakInProgress', () async {
      final session = await breakService.requireBreak(
        packageName: 'com.example.social',
        breakDurationSeconds: 300,
      );

      final inProgress = await breakService.startBreakTimer(session);
      expect(inProgress.currentState, BreakState.breakInProgress);
    });

    test('startExercises transitions to exerciseInProgress', () async {
      final session = await breakService.requireBreak(
        packageName: 'com.example.social',
        breakDurationSeconds: 300,
      );

      final inEx = await breakService.startExercises(session);
      expect(inEx.currentState, BreakState.exerciseInProgress);
    });

    test('completeExercises logs exercises and transitions to awaitingPin', () async {
      final session = await breakService.requireBreak(
        packageName: 'com.example.social',
        breakDurationSeconds: 300,
      );

      final logs = [
        ExerciseLog(
          exerciseId: 'pushups',
          exerciseName: 'Push-ups',
          repetitions: 15,
          breakSessionId: session.id,
          packageName: session.packageName,
        ),
        ExerciseLog(
          exerciseId: 'squats',
          exerciseName: 'Squats',
          repetitions: 20,
          breakSessionId: session.id,
          packageName: session.packageName,
        ),
      ];

      final awaiting = await breakService.completeExercises(session, logs);
      expect(awaiting.currentState, BreakState.awaitingPin);
    });

    test('validateAndUnlockBreak validates PIN and transitions to eligibleToResume', () async {
      final session = await breakService.requireBreak(
        packageName: 'com.example.social',
        breakDurationSeconds: 300,
      );
      final pinState = await pinService.getCurrentPinState();

      // Wrong PIN
      final fail = await breakService.validateAndUnlockBreak(session, '00000000');
      if (pinState.currentPin != '00000000') {
        expect(fail, isFalse);
      }

      // Correct PIN
      final success = await breakService.validateAndUnlockBreak(session, pinState.currentPin);
      expect(success, isTrue);

      // Check persisted state in database
      final active = await breakService.getActiveBreak(session.packageName);
      // Since eligibleToResume is not considered active, active should now be null
      expect(active, isNull);
    });

    test('cancelBreak cancels active session', () async {
      final session = await breakService.requireBreak(
        packageName: 'com.example.social',
        breakDurationSeconds: 300,
      );

      await breakService.cancelBreak(session);
      final active = await breakService.getActiveBreak(session.packageName);
      expect(active, isNull);
    });
  });
}
