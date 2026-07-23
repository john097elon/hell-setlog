import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/domain/entities/routine_item.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';
import 'package:heal_setlog/domain/repositories/routine_repository.dart';
import 'package:heal_setlog/domain/repositories/workout_repository.dart';
import 'package:heal_setlog/features/routine/application/start_from_routine_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoutineRepository extends Mock implements RoutineRepository {}
class _MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  test('starts once and adds one draft for every planned routine set', () async {
    final routines = _MockRoutineRepository();
    final workouts = _MockWorkoutRepository();
    when(() => workouts.getActiveSession()).thenAnswer(
      (_) async => const Err(NotFoundFailure()),
    );
    when(() => routines.getItems('routine')).thenAnswer(
      (_) async => Ok(<RoutineItem>[
        _item('one', targetSets: 3),
        _item('two', targetSets: 2),
      ]),
    );
    when(() => workouts.startSession(routineId: 'routine')).thenAnswer(
      (_) async => Ok(_session()),
    );
    when(
      () => workouts.addSet(
        sessionId: any(named: 'sessionId'),
        exerciseId: any(named: 'exerciseId'),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        rpe: any(named: 'rpe'),
        isWarmup: any(named: 'isWarmup'),
        restSeconds: any(named: 'restSeconds'),
      ),
    ).thenAnswer((_) async => Ok(_set()));

    final result = await StartFromRoutineController(routines, workouts).start('routine');

    expect(result.isOk, isTrue);
    verify(() => workouts.startSession(routineId: 'routine')).called(1);
    verify(
      () => workouts.addSet(
        sessionId: 'session',
        exerciseId: any(named: 'exerciseId'),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        isWarmup: any(named: 'isWarmup'),
      ),
    ).called(5);
  });
}

RoutineItem _item(String id, {required int targetSets}) => RoutineItem(
  id: id,
  routineId: 'routine',
  exerciseId: 'exercise-$id',
  order: 0,
  targetSets: targetSets,
  targetReps: 10,
  targetWeight: 50,
  updatedAt: DateTime(2026),
);

WorkoutSession _session() => WorkoutSession(
  id: 'session',
  userId: 'user',
  startedAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

WorkoutSet _set() => WorkoutSet(
  id: 'set',
  sessionId: 'session',
  exerciseId: 'exercise',
  setIndex: 0,
  weight: 50,
  reps: 10,
  updatedAt: DateTime(2026),
);
