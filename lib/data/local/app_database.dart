import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'daos/exercise_dao.dart';
import 'tables/exercises_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Exercises], daos: [ExerciseDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  return NativeDatabase(File(path.join(directory.path, 'heal_setlog.sqlite')));
});
