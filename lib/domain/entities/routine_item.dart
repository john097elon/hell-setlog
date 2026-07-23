import 'workout_set.dart';

class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.order,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.local,
  });
  final String id;
  final String routineId;
  final String exerciseId;
  final int order;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  RoutineItem copyWith({
    int? order,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => RoutineItem(
    id: id,
    routineId: routineId,
    exerciseId: exerciseId,
    order: order ?? this.order,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps ?? this.targetReps,
    targetWeight: targetWeight ?? this.targetWeight,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus,
  );
}
