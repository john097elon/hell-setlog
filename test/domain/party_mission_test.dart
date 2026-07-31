import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/party_mission.dart';

void main() {
  test('주 시작은 월요일 자정이다', () {
    // 2026-07-31은 금요일이라 그 주 월요일은 7월 27일이다.
    expect(weekStartOf(DateTime(2026, 7, 31, 20, 30)), DateTime(2026, 7, 27));
    // 월요일 당일은 그날 자정이 시작이다.
    expect(weekStartOf(DateTime(2026, 7, 27, 0, 5)), DateTime(2026, 7, 27));
    // 일요일은 같은 주의 월요일로 붙는다.
    expect(weekStartOf(DateTime(2026, 8, 2, 23, 59)), DateTime(2026, 7, 27));
  });

  test('목표를 안 정하면 인원당 주 3회다', () {
    expect(defaultWeeklyGoal(4), 12);
    expect(defaultWeeklyGoal(1), 3);
    // 인원이 0으로 오더라도 목표가 0이 되면 안 된다.
    expect(defaultWeeklyGoal(0), 3);
  });

  test('진행률과 남은 횟수를 계산한다', () {
    final mission = PartyMission(
      goalSessions: 12,
      doneSessions: 3,
      contributions: const <PartyContribution>[],
      weekStart: DateTime(2026, 7, 27),
    );

    expect(mission.progress, closeTo(0.25, 0.001));
    expect(mission.remaining, 9);
    expect(mission.isComplete, isFalse);
  });

  test('목표를 넘겨도 진행률은 1을 넘지 않는다', () {
    final mission = PartyMission(
      goalSessions: 10,
      doneSessions: 14,
      contributions: const <PartyContribution>[],
      weekStart: DateTime(2026, 7, 27),
    );

    expect(mission.progress, 1);
    expect(mission.remaining, 0);
    expect(mission.isComplete, isTrue);
  });

  test('목표가 0이어도 나누기에서 터지지 않는다', () {
    final mission = PartyMission(
      goalSessions: 0,
      doneSessions: 0,
      contributions: const <PartyContribution>[],
      weekStart: DateTime(2026, 7, 27),
    );

    expect(mission.progress, 0);
    expect(mission.isComplete, isTrue);
  });
}
