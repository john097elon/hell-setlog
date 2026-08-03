import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';
import 'package:heal_setlog/domain/repositories/workout_repository.dart';
import 'package:heal_setlog/features/workout_log/application/workout_providers.dart';
import 'package:heal_setlog/features/workout_log/application/workout_session_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  setUpAll(() => registerFallbackValue(_set('fallback')));

  test('complete draft calls completeSet once', () async {
    final repository = _MockWorkoutRepository();
    final added = _set('added');
    final completed = _set('added', completed: true);
    when(
      () => repository.addSet(
        sessionId: any(named: 'sessionId'),
        exerciseId: any(named: 'exerciseId'),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        rpe: any(named: 'rpe'),
        isWarmup: any(named: 'isWarmup'),
        restSeconds: any(named: 'restSeconds'),
      ),
    ).thenAnswer((_) async => Ok(added));
    when(
      () => repository.completeSet(any(), completed: any(named: 'completed')),
    ).thenAnswer((_) async => Ok(completed));
    final container = ProviderContainer(
      overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(workoutSessionControllerProvider)
        .completeDraft(
          sessionId: 'session',
          exerciseId: 'exercise',
          weight: 60,
          reps: 10,
        );

    verify(() => repository.completeSet('added')).called(1);
  });

  test('prefills from the previous set of the selected exercise', () {
    final values = prefillForExercise([
      _set('one', weight: 72.5, reps: 8),
    ], 'exercise');
    expect(values.weight, 72.5);
    expect(values.reps, 8);
  });

  test(
    'distance draft is stored in distanceMeters before completion',
    () async {
      final repository = _MockWorkoutRepository();
      final added = _set('distance');
      when(
        () => repository.addSet(
          sessionId: any(named: 'sessionId'),
          exerciseId: any(named: 'exerciseId'),
          weight: any(named: 'weight'),
          reps: any(named: 'reps'),
          rpe: any(named: 'rpe'),
          isWarmup: any(named: 'isWarmup'),
          restSeconds: any(named: 'restSeconds'),
        ),
      ).thenAnswer((_) async => Ok(added));
      when(() => repository.updateSet(any())).thenAnswer((invocation) async {
        return Ok(invocation.positionalArguments.single as WorkoutSet);
      });
      when(
        () => repository.completeSet(any(), completed: any(named: 'completed')),
      ).thenAnswer((_) async => Ok(added.copyWith(isCompleted: true)));
      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(workoutSessionControllerProvider)
          .completeDraft(
            sessionId: 'session',
            exerciseId: 'running',
            weight: 0,
            reps: 0,
            distanceMeters: 5000,
          );

      final saved =
          verify(() => repository.updateSet(captureAny())).captured.single
              as WorkoutSet;
      expect(saved.distanceMeters, 5000);
      expect(saved.durationSeconds, isNull);
    },
  );

  test('duration draft stores durationSeconds and intensity', () async {
    final repository = _MockWorkoutRepository();
    final added = _set('duration');
    when(
      () => repository.addSet(
        sessionId: any(named: 'sessionId'),
        exerciseId: any(named: 'exerciseId'),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        rpe: any(named: 'rpe'),
        isWarmup: any(named: 'isWarmup'),
        restSeconds: any(named: 'restSeconds'),
      ),
    ).thenAnswer((_) async => Ok(added));
    when(() => repository.updateSet(any())).thenAnswer((invocation) async {
      return Ok(invocation.positionalArguments.single as WorkoutSet);
    });
    when(
      () => repository.completeSet(any(), completed: any(named: 'completed')),
    ).thenAnswer((_) async => Ok(added.copyWith(isCompleted: true)));
    final container = ProviderContainer(
      overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(workoutSessionControllerProvider)
        .completeDraft(
          sessionId: 'session',
          exerciseId: 'grappling',
          weight: 0,
          reps: 0,
          durationSeconds: 3600,
          intensity: 4,
        );

    final saved =
        verify(() => repository.updateSet(captureAny())).captured.single
            as WorkoutSet;
    expect(saved.durationSeconds, 3600);
    expect(saved.intensity, 4);
  });
}

WorkoutSet _set(
  String id, {
  double weight = 60,
  int reps = 10,
  bool completed = false,
}) => WorkoutSet(
  id: id,
  sessionId: 'session',
  exerciseId: 'exercise',
  setIndex: 0,
  weight: weight,
  reps: reps,
  isCompleted: completed,
  updatedAt: DateTime(2026),
);
