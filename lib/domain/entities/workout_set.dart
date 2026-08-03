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
    this.distanceMeters,
    this.durationSeconds,
    this.intensity,
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

  /// 거리 종목(러닝·수영·사이클)의 거리.
  final double? distanceMeters;

  /// 시간으로 기록하는 종목의 소요 시간.
  final int? durationSeconds;

  /// 시간 종목의 체감 강도 1~5.
  final int? intensity;

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
    double? distanceMeters,
    int? durationSeconds,
    int? intensity,
    double? rpe,
    bool? isWarmup,
    bool? isCompleted,
    int? restSeconds,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    // 삭제 취소는 deletedAt을 실제로 비워야 한다. `deletedAt: null`만으로는 지워지지 않는다.
    bool clearDeletedAt = false,
  }) => WorkoutSet(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    intensity: intensity ?? this.intensity,
    rpe: rpe ?? this.rpe,
    isWarmup: isWarmup ?? this.isWarmup,
    isCompleted: isCompleted ?? this.isCompleted,
    restSeconds: restSeconds ?? this.restSeconds,
    completedAt: completedAt ?? this.completedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
