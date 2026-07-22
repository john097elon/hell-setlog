import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';
import 'package:heal_setlog/domain/usecases/calculate_session_volume.dart';

void main() {
  WorkoutSet set({
    double weight = 100,
    int reps = 5,
    bool warmup = false,
    bool completed = true,
    DateTime? deletedAt,
  }) => WorkoutSet(
    id: 'set',
    sessionId: 'session',
    exerciseId: 'exercise',
    setIndex: 0,
    weight: weight,
    reps: reps,
    isWarmup: warmup,
    isCompleted: completed,
    updatedAt: DateTime(2026),
    deletedAt: deletedAt,
  );

  test('sums only completed non-warmup non-deleted sets', () {
    expect(calculateSessionVolume([set(), set(weight: 50, reps: 10)]), 1000);
    expect(calculateSessionVolume([set(warmup: true)]), 0);
    expect(calculateSessionVolume([set(completed: false)]), 0);
    expect(calculateSessionVolume([set(deletedAt: DateTime(2026))]), 0);
  });

  test('returns zero for empty and bodyweight sets', () {
    expect(calculateSessionVolume([]), 0);
    expect(calculateSessionVolume([set(weight: 0)]), 0);
  });
}
