import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;

import '../../../core/error/result.dart';
import '../../../core/error/failure.dart';
import '../../../core/constants/workout.dart';
import '../../../domain/entities/workout_set.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'rest_timer_controller.dart';
import 'workout_providers.dart';
import '../../../data/repositories/supabase_sync_repository.dart';

part 'workout_session_controller.g.dart';

/// Coordinates UI actions while keeping repository calls out of presentation.
@riverpod
WorkoutSessionController workoutSessionController(
  WorkoutSessionControllerRef ref,
) => WorkoutSessionController(ref.watch(workoutRepositoryProvider), ref);

class WorkoutSessionController {
  WorkoutSessionController(this._repository, this._ref);

  final WorkoutRepository _repository;
  final Ref _ref;

  Future<Result<WorkoutSession, Failure>> startSession() =>
      _repository.startSession();

  Future<Result<WorkoutSession, Failure>> endSession(String sessionId) async {
    final ended = await _repository.endSession(sessionId);
    ended.when(
      ok: (_) => unawaited(_ref.read(syncRepositoryProvider).pushAll()),
      err: (_) {},
    );
    return ended;
  }

  Future<Result<WorkoutSet, Failure>> completeDraft({
    required String sessionId,
    required String exerciseId,
    required double weight,
    required int reps,
    int restSeconds = 0,
  }) async {
    final added = await _repository.addSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
      restSeconds: restSeconds,
    );
    return added.when(
      ok: (set) async {
        return _completeSet(set.id);
      },
      err: (failure) async => Err(failure),
    );
  }

  Future<Result<WorkoutSet, Failure>> completeSet(String setId) =>
      _completeSet(setId);

  Future<Result<WorkoutSet, Failure>> _completeSet(String setId) async {
    final completed = await _repository.completeSet(setId);
    completed.when(
      ok: (value) => _ref
          .read(restTimerProvider.notifier)
          .start(
            value.restSeconds == 0 ? kDefaultRestSeconds : value.restSeconds,
          ),
      err: (_) {},
    );
    return completed;
  }

  Future<Result<void, Failure>> deleteSet(String setId) =>
      _repository.deleteSet(setId);

  /// 루틴으로 만든 계획 세트의 실제 수행값을 반영한다.
  Future<Result<WorkoutSet, Failure>> updatePlannedSet(
    WorkoutSet set, {
    double? weight,
    int? reps,
  }) => _repository.updateSet(set.copyWith(weight: weight, reps: reps));

  Future<Result<WorkoutSet, Failure>> restoreSet(WorkoutSet set) =>
      _repository.updateSet(set.copyWith(clearDeletedAt: true));
}

/// Values used for the next set row, copied from the most recent set.
SetPrefill prefillForExercise(Iterable<WorkoutSet> sets, String exerciseId) {
  final matching = sets.where((set) => set.exerciseId == exerciseId);
  final previous = matching.isEmpty ? null : matching.last;
  return SetPrefill(previous?.weight ?? 0, previous?.reps ?? 0);
}

class SetPrefill {
  const SetPrefill(this.weight, this.reps);
  final double weight;
  final int reps;
}
