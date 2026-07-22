/// Synchronization state reserved for the future P3 sync layer.
enum SyncStatus { local, pending, synced }

/// One recorded set in a workout session.
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
    required this.weight,
    required this.reps,
    this.rpe,
    this.isWarmup = false,
    this.isCompleted = false,
    this.restSeconds = 0,
    this.completedAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.local,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final int setIndex;
  final double weight;
  final int reps;
  final double? rpe;
  final bool isWarmup;
  final bool isCompleted;
  final int restSeconds;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  WorkoutSet copyWith({
    String? id,
    String? sessionId,
    String? exerciseId,
    int? setIndex,
    double? weight,
    int? reps,
    double? rpe,
    bool? isWarmup,
    bool? isCompleted,
    int? restSeconds,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => WorkoutSet(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    rpe: rpe ?? this.rpe,
    isWarmup: isWarmup ?? this.isWarmup,
    isCompleted: isCompleted ?? this.isCompleted,
    restSeconds: restSeconds ?? this.restSeconds,
    completedAt: completedAt ?? this.completedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
