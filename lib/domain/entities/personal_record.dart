import 'workout_set.dart';

enum PrType { oneRm, volume, reps }

class PersonalRecord {
  const PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.type,
    required this.value,
    required this.achievedAt,
    required this.sessionId,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.local,
  });

  final String id;
  final String userId;
  final String exerciseId;
  final PrType type;
  final double value;
  final DateTime achievedAt;
  final String sessionId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
}
