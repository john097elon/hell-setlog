/// 파티원 한 명의 이번 주 기여.
class PartyContribution {
  const PartyContribution({
    required this.userId,
    required this.nickname,
    required this.sessions,
    required this.volumeKg,
    required this.xp,
    this.avatarUrl,
  });

  final String userId;
  final String nickname;
  final int sessions;
  final double volumeKg;
  final int xp;
  final String? avatarUrl;
}

/// 파티의 이번 주 미션 현황.
class PartyMission {
  const PartyMission({
    required this.goalSessions,
    required this.doneSessions,
    required this.contributions,
    required this.weekStart,
  });

  /// 이번 주 파티가 함께 채워야 할 운동 횟수.
  final int goalSessions;

  /// 지금까지 채운 횟수.
  final int doneSessions;

  /// 기여가 많은 순서.
  final List<PartyContribution> contributions;
  final DateTime weekStart;

  bool get isComplete => doneSessions >= goalSessions;

  int get remaining =>
      doneSessions >= goalSessions ? 0 : goalSessions - doneSessions;

  double get progress =>
      goalSessions <= 0 ? 0 : (doneSessions / goalSessions).clamp(0.0, 1.0);
}

/// 목표를 정하지 않은 파티의 기본값. 인원당 주 3회.
int defaultWeeklyGoal(int memberCount) =>
    (memberCount <= 0 ? 1 : memberCount) * 3;

/// 이번 주 시작(월요일 자정).
DateTime weekStartOf(DateTime now) {
  final date = DateTime(now.year, now.month, now.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}
