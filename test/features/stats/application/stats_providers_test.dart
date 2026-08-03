import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/entities/exercise.dart' as domain;
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';

void main() {
  test('무게가 없는 완료 기록도 갈래별로 집계한다', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    await database
        .into(database.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'running',
            name: 'Outdoor Running',
            nameKo: '야외 러닝',
            muscleGroup: domain.MuscleGroup.fullBody.index,
            equipment: domain.Equipment.other.index,
            discipline: Value(Discipline.running.index),
          ),
        );
    await database
        .into(database.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: 'session',
            userId: 'user',
            startedAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.workoutSets)
        .insert(
          WorkoutSetsCompanion.insert(
            id: 'set',
            sessionId: 'session',
            exerciseId: 'running',
            setIndex: 1,
            weight: 0,
            reps: 0,
            distanceMeters: const Value(5000),
            durationSeconds: const Value(1800),
            isCompleted: const Value(true),
            updatedAt: now,
          ),
        );
    final container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      weeklyDisciplineCountsProvider().future,
    );

    expect(
      result.when(ok: (counts) => counts, err: (failure) => throw failure),
      const <Discipline, int>{Discipline.running: 1},
    );
  });
}
