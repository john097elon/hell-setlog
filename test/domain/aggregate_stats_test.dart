import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';
import 'package:heal_setlog/domain/usecases/aggregate_stats.dart';

void main() {
  final now = DateTime.now();
  WorkoutSet set(
    String id,
    String sessionId,
    String exerciseId, {
    double weight = 100,
    int reps = 5,
    bool completed = true,
    bool warmup = false,
    DateTime? deletedAt,
  }) => WorkoutSet(
    id: id,
    sessionId: sessionId,
    exerciseId: exerciseId,
    setIndex: 0,
    weight: weight,
    reps: reps,
    isCompleted: completed,
    isWarmup: warmup,
    updatedAt: now,
    deletedAt: deletedAt,
  );

  test('groups only working sets by muscle group', () {
    final volumes = bodyPartVolume(
      [
        set('1', 's1', 'bench'),
        set('2', 's1', 'squat', weight: 80, reps: 10),
        set('3', 's1', 'bench', warmup: true),
        set('4', 's1', 'bench', completed: false),
        set('5', 's1', 'bench', deletedAt: now),
      ],
      {'bench': MuscleGroup.chest, 'squat': MuscleGroup.legs},
    );

    expect(volumes, {MuscleGroup.chest: 500, MuscleGroup.legs: 800});
  });

  test('groups current days by date and omits empty dates', () {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessions = [
      WorkoutSession(
        id: 'today',
        userId: 'u',
        startedAt: today,
        updatedAt: today,
      ),
      WorkoutSession(
        id: 'yesterday',
        userId: 'u',
        startedAt: yesterday,
        updatedAt: yesterday,
      ),
    ];
    final volumes = dailyVolume(sessions, [
      set('1', 'today', 'bench'),
      set('2', 'yesterday', 'bench', weight: 50, reps: 10),
    ]);

    expect(volumes, {today: 500, yesterday: 500});
    expect(
      volumes.containsKey(today.subtract(const Duration(days: 2))),
      isFalse,
    );
  });
}
