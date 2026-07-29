import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/repositories/routine_repository.dart';
import '../../../domain/repositories/workout_repository.dart';
import '../../../domain/usecases/start_session_from_routine.dart';
import '../../workout_log/application/workout_providers.dart';
import 'routine_providers.dart';

part 'start_from_routine_controller.g.dart';

@riverpod
StartFromRoutineController startFromRoutineController(
  StartFromRoutineControllerRef ref,
) => StartFromRoutineController(
  ref.watch(routineRepositoryProvider),
  ref.watch(workoutRepositoryProvider),
);

class StartFromRoutineOutcome {
  const StartFromRoutineOutcome({required this.session, required this.started});

  final WorkoutSession session;
  final bool started;
}

/// Starts one routine session and creates its incomplete planned sets.
class StartFromRoutineController {
  StartFromRoutineController(this._routineRepository, this._workoutRepository);

  final RoutineRepository _routineRepository;
  final WorkoutRepository _workoutRepository;

  Future<Result<StartFromRoutineOutcome, Failure>> start(
    String routineId,
  ) async {
    final active = await _workoutRepository.getActiveSession();
    if (active.isOk) {
      return active.when(
        ok: (session) =>
            Ok(StartFromRoutineOutcome(session: session, started: false)),
        err: (failure) => Err(failure),
      );
    }
    final activeFailure = active.when(
      ok: (_) => null,
      err: (failure) => failure,
    );
    if (activeFailure is! NotFoundFailure) {
      return Err(activeFailure!);
    }
    final items = await _routineRepository.getItems(routineId);
    return items.when(
      ok: (value) async {
        final session = await _workoutRepository.startSession(
          routineId: routineId,
        );
        return session.when(
          ok: (created) async {
            for (final draft in plannedSetsFromRoutine(value)) {
              final added = await _workoutRepository.addSet(
                sessionId: created.id,
                exerciseId: draft.exerciseId,
                weight: draft.weight,
                reps: draft.reps,
                isWarmup: draft.isWarmup,
              );
              if (!added.isOk) {
                return added.when(
                  ok: (_) => const Err<StartFromRoutineOutcome, Failure>(
                    DatabaseFailure(),
                  ),
                  err: Err<StartFromRoutineOutcome, Failure>.new,
                );
              }
            }
            return Ok(StartFromRoutineOutcome(session: created, started: true));
          },
          err: Err<StartFromRoutineOutcome, Failure>.new,
        );
      },
      err: Err<StartFromRoutineOutcome, Failure>.new,
    );
  }
}
