import 'workout_set.dart';

/// A locally recorded workout session.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId,
    this.routineId,
    this.partyId,
    required this.startedAt,
    this.endedAt,
    this.memo,
    this.totalVolume = 0,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.local,
  });

  final String id;
  final String userId;
  final String? routineId;
  final String? partyId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? memo;
  final double totalVolume;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get isActive => endedAt == null && deletedAt == null;

  WorkoutSession copyWith({
    String? id,
    String? userId,
    String? routineId,
    String? partyId,
    DateTime? startedAt,
    DateTime? endedAt,
    String? memo,
    double? totalVolume,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => WorkoutSession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    routineId: routineId ?? this.routineId,
    partyId: partyId ?? this.partyId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    memo: memo ?? this.memo,
    totalVolume: totalVolume ?? this.totalVolume,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
