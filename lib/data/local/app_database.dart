import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'daos/exercise_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/routine_dao.dart';
import 'daos/stats_dao.dart';
import 'tables/exercises_table.dart';
import 'tables/workout_sessions_table.dart';
import 'tables/workout_sets_table.dart';
import 'tables/routines_table.dart';
import 'tables/routine_items_table.dart';
import 'tables/personal_records_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutSessions,
    WorkoutSets,
    Routines,
    RoutineItems,
    PersonalRecords,
  ],
  daos: [ExerciseDao, WorkoutDao, RoutineDao, StatsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(workoutSessions);
        await migrator.createTable(workoutSets);
      }
      if (from < 3) {
        await migrator.createTable(routines);
        await migrator.createTable(routineItems);
      }
      if (from < 4) await migrator.createTable(personalRecords);
      if (from < 5) {
        await migrator.addColumn(exercises, exercises.userId);
        await customStatement('ALTER TABLE exercises ADD COLUMN created_at INTEGER');
        await customStatement('ALTER TABLE exercises ADD COLUMN updated_at INTEGER');
        await migrator.addColumn(exercises, exercises.deletedAt);
        await migrator.addColumn(exercises, exercises.syncStatus);
        await customStatement(
          "UPDATE exercises SET created_at = CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER), updated_at = CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
        );
      }
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  return NativeDatabase(File(path.join(directory.path, 'heal_setlog.sqlite')));
});
