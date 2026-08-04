import '../../domain/entities/workout_set.dart';
import '../local/app_database.dart' as database;

/// 저장된 세트를 도메인 세트로 옮긴다.
///
/// 여러 저장소가 각자 옮기던 것을 한곳으로 모았다. 갈라져 있으면 컬럼을 늘릴 때
/// 한쪽만 고쳐서 기록이 조용히 사라진다.
WorkoutSet workoutSetFromRow(database.WorkoutSet set) => WorkoutSet(
  id: set.id,
  sessionId: set.sessionId,
  exerciseId: set.exerciseId,
  setIndex: set.setIndex,
  weight: set.weight,
  reps: set.reps,
  rpe: set.rpe,
  distanceMeters: set.distanceMeters,
  durationSeconds: set.durationSeconds,
  intensity: set.intensity,
  isWarmup: set.isWarmup,
  isCompleted: set.isCompleted,
  restSeconds: set.restSeconds,
  completedAt: set.completedAt,
  updatedAt: set.updatedAt,
  deletedAt: set.deletedAt,
  syncStatus: SyncStatus.values[set.syncStatus],
);
