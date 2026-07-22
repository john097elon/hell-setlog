import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'daos/exercise_dao.dart';
import 'daos/workout_dao.dart';
import 'tables/exercises_table.dart';
import 'tables/workout_sessions_table.dart';
import 'tables/workout_sets_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Exercises, WorkoutSessions, WorkoutSets],
  daos: [ExerciseDao, WorkoutDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(workoutSessions);
        await migrator.createTable(workoutSets);
      }
    },
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  return NativeDatabase(File(path.join(directory.path, 'heal_setlog.sqlite')));
});
