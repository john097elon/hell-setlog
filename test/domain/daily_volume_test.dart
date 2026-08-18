import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';
import 'package:heal_setlog/domain/usecases/aggregate_stats.dart';

void main() {
  final today = DateTime(2026, 8, 16, 10);
  final yesterday = today.subtract(const Duration(days: 1));

  WorkoutSession session(String id, DateTime startedAt) => WorkoutSession(
    id: id,
    userId: 'me',
    startedAt: startedAt,
    updatedAt: startedAt,
  );

  WorkoutSet set(String id, String sessionId, DateTime? completedAt) =>
      WorkoutSet(
        id: id,
        sessionId: sessionId,
        exerciseId: 'e1',
        setIndex: 0,
        weight: 50,
        reps: 10,
        isCompleted: true,
        completedAt: completedAt,
        updatedAt: completedAt ?? today,
      );

  test('세트를 마친 날짜에 볼륨이 쌓인다', () {
    // 어제 시작해 자정을 넘긴 세션. 예전에는 전부 어제로 갔다.
    final volumes = dailyVolume(
      <WorkoutSession>[session('s1', yesterday)],
      <WorkoutSet>[
        set('a', 's1', yesterday),
        set('b', 's1', today),
      ],
      days: 7,
    );

    expect(volumes[DateTime(2026, 8, 15)], 500);
    expect(volumes[DateTime(2026, 8, 16)], 500);
  });

  test('완료 시각이 없으면 세션 날짜로 둔다', () {
    final volumes = dailyVolume(
      <WorkoutSession>[session('s1', yesterday)],
      <WorkoutSet>[set('a', 's1', null)],
      days: 7,
    );

    expect(volumes[DateTime(2026, 8, 15)], 500);
  });

  test('지운 세션의 기록은 세지 않는다', () {
    final removed = WorkoutSession(
      id: 's1',
      userId: 'me',
      startedAt: yesterday,
      updatedAt: yesterday,
      deletedAt: yesterday,
    );
    final volumes = dailyVolume(<WorkoutSession>[removed], <WorkoutSet>[
      set('a', 's1', null),
    ], days: 7);

    expect(volumes, isEmpty);
  });
}
