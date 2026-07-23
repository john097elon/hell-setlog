import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart'
    hide PersonalRecord, WorkoutSession, WorkoutSet;
import 'package:heal_setlog/data/repositories/stats_repository_impl.dart';
import 'package:heal_setlog/data/repositories/workout_repository_impl.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/personal_record.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';

void main() {
  late AppDatabase database;
  late WorkoutRepositoryImpl workouts;
  late StatsRepositoryImpl stats;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    workouts = WorkoutRepositoryImpl(database.workoutDao);
    stats = StatsRepositoryImpl(database.statsDao);
  });
  tearDown(() => database.close());

  test('records only PRs that exceed the existing record', () async {
    await database
        .into(database.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'bench',
            name: 'Bench',
            nameKo: '벤치',
            muscleGroup: MuscleGroup.chest.index,
            equipment: Equipment.barbell.index,
          ),
        );
    final first = await _completedBenchSession(workouts, 100, 5);
    final records = _records(await stats.updateRecordsForSession(first.id));
    final tied = _records(await stats.updateRecordsForSession(first.id));

    expect(records.map((record) => record.type).toSet(), {
      PrType.oneRm,
      PrType.volume,
      PrType.reps,
    });
    expect(tied, isEmpty);
  });

  test('migrates v3 to v4 without removing existing data', () async {
    await database.close();
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE exercises (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, name_ko TEXT NOT NULL, muscle_group INTEGER NOT NULL, equipment INTEGER NOT NULL, is_custom INTEGER NOT NULL DEFAULT 0, thumbnail_url TEXT)',
          );
          raw.execute(
            "INSERT INTO exercises VALUES ('bench', 'Bench', '벤치', 0, 0, 0, NULL)",
          );
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );

    expect((await database.exerciseDao.getById('bench'))?.name, 'Bench');
    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'personal_records'",
        )
        .getSingleOrNull();
    expect(table, isNotNull);
  });
}

Future<WorkoutSession> _completedBenchSession(
  WorkoutRepositoryImpl workouts,
  double weight,
  int reps,
) async {
  final session = _session(await workouts.startSession());
  final set = _set(
    await workouts.addSet(
      sessionId: session.id,
      exerciseId: 'bench',
      weight: weight,
      reps: reps,
    ),
  );
  await workouts.completeSet(set.id);
  return _session(await workouts.endSession(session.id));
}

WorkoutSession _session(Object result) => (result as dynamic).when(
  ok: (WorkoutSession value) => value,
  err: (Object _) => throw StateError('expected session'),
);

dynamic _set(Object result) => (result as dynamic).when(
  ok: (value) => value,
  err: (Object _) => throw StateError('expected set'),
);

List<PersonalRecord> _records(Object result) => (result as dynamic).when(
  ok: (List<PersonalRecord> value) => value,
  err: (Object _) => throw StateError('expected records'),
);
