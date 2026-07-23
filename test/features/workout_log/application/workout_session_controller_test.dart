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
