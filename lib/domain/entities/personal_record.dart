import 'workout_set.dart';

/// 개인 기록 종류. 종목에 따라 세우는 기록이 다르다.
///
/// 페이스는 낮을수록 좋아서 그대로 비교하면 최고 기록이 뒤집힌다. 그래서
/// 속도(m/s)로 저장하고 화면에서만 페이스로 바꿔 보여준다.
enum PrType { oneRm, volume, reps, distance, duration, speed }

/// 화면에 쓰는 기록 이름.
String prTypeLabel(PrType type) => switch (type) {
  PrType.oneRm => '1RM',
  PrType.volume => '볼륨',
  PrType.reps => '최고 횟수',
  PrType.distance => '최장 거리',
  PrType.duration => '최장 시간',
  PrType.speed => '최고 속도',
};

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
