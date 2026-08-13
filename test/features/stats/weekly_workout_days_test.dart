import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';

/// 운동일을 볼륨으로 세면 러닝만 한 주가 0일이 된다. 그러지 않는지 본다.
void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    );
    await database.exerciseDao.insertAll(<ExercisesCompanion>[
      ExercisesCompanion.insert(
        id: 'run',
        name: 'Run',
        nameKo: '러닝',
        muscleGroup: MuscleGroup.fullBody.index,
        equipment: Equipment.bodyweight.index,
        discipline: Value(Discipline.running.index),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    return database.close();
  });

  Future<void> logRun(DateTime when) async {
    final sessionId = 'session-${when.day}';
    await database
        .into(database.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: sessionId,
            userId: 'me',
            startedAt: when,
            updatedAt: when,
          ),
        );
    await database
        .into(database.workoutSets)
        .insert(
          WorkoutSetsCompanion.insert(
            id: 'set-${when.day}',
            sessionId: sessionId,
            exerciseId: 'run',
            setIndex: 0,
            weight: 0,
            reps: 0,
            distanceMeters: const Value(5000),
            durationSeconds: const Value(1500),
            isCompleted: const Value(true),
            completedAt: Value(when),
            updatedAt: when,
          ),
        );
  }

  test('무게가 없는 운동도 운동일로 센다', () async {
    final today = DateTime.now();
    await logRun(today.subtract(const Duration(days: 1)));
    await logRun(today);

    final result = await container.read(weeklyWorkoutDaysProvider().future);
    final days = result.when(ok: (value) => value, err: (e) => throw e);

    // 볼륨 기준이면 0일이 나온다.
    final volumes = await container.read(weeklyVolumeProvider().future);
    final total = volumes
        .when(ok: (value) => value, err: (e) => throw e)
        .values
        .fold<double>(0, (sum, value) => sum + value);

    expect(days, 2);
    expect(total, 0);
  });
}
