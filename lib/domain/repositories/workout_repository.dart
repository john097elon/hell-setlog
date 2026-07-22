import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/workout_session.dart';
import '../entities/workout_set.dart';

abstract class WorkoutRepository {
  Future<Result<WorkoutSession, Failure>> startSession({
    String? routineId,
    String? partyId,
  });
  Future<Result<WorkoutSession, Failure>> getActiveSession();
  Future<Result<WorkoutSession, Failure>> endSession(
    String sessionId, {
    String? memo,
  });
  Future<Result<WorkoutSet, Failure>> addSet({
    required String sessionId,
    required String exerciseId,
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmup = false,
    int restSeconds = 0,
  });
  Future<Result<WorkoutSet, Failure>> updateSet(WorkoutSet set);
  Future<Result<WorkoutSet, Failure>> completeSet(
    String setId, {
    bool completed = true,
  });
  Future<Result<void, Failure>> deleteSet(String setId);
  Stream<List<WorkoutSet>> watchSets(String sessionId);
}
