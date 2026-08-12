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
  int get schemaVersion => 7;

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
        await customStatement(
          'ALTER TABLE exercises ADD COLUMN created_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE exercises ADD COLUMN updated_at INTEGER',
        );
        await migrator.addColumn(exercises, exercises.deletedAt);
        await migrator.addColumn(exercises, exercises.syncStatus);
        await customStatement(
          "UPDATE exercises SET created_at = CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER), updated_at = CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
        );
      }
      if (from < 6) {
        // 헬스 외 종목(러닝·수영·주짓수 등)을 담기 위한 열이다.
        // 기존 기록은 웨이트(discipline 0)로 남는다.
        // 앞 단계에서 표를 새로 만들었으면 열이 이미 들어 있다. 기기마다
        // 올라온 경로가 달라 있는지 확인하고 없을 때만 추가한다.
        await _addColumnIfMissing(migrator, workoutSets, 'distance_meters');
        await _addColumnIfMissing(migrator, workoutSets, 'duration_seconds');
        await _addColumnIfMissing(migrator, workoutSets, 'intensity');
        await _addColumnIfMissing(migrator, exercises, 'discipline');
      }
      if (from < 7) {
        // 5단계에서 created_at·updated_at을 DEFAULT 없이 붙였다. 그때 있던 행만
        // 채워 두어서, 그 뒤에 추가된 종목은 값이 비어 버렸다. 값이 빈 행은
        // 읽는 순간 터지고 종목 목록 전체가 사라진다.
        await customStatement(
          "UPDATE exercises SET created_at = CAST(strftime('%s', "
          'CURRENT_TIMESTAMP) AS INTEGER) WHERE created_at IS NULL',
        );
        await customStatement(
          "UPDATE exercises SET updated_at = CAST(strftime('%s', "
          'CURRENT_TIMESTAMP) AS INTEGER) WHERE updated_at IS NULL',
        );
      }
    },
  );

  /// 표가 있고 그 열이 없을 때만 추가한다. 이미 있으면 조용히 넘어간다.
  Future<void> _addColumnIfMissing(
    Migrator migrator,
    TableInfo<Table, dynamic> table,
    String columnName,
  ) async {
    final name = table.actualTableName;
    final exists = await customSelect(
      "select name from sqlite_master where type = 'table' and name = ?",
      variables: <Variable<Object>>[Variable<String>(name)],
    ).getSingleOrNull();
    if (exists == null) return;
    final columns = await customSelect('pragma table_info($name)').get();
    final has = columns.any((row) => row.data['name'] == columnName);
    if (has) return;
    final column = table.$columns.firstWhere((item) => item.name == columnName);
    await migrator.addColumn(table, column);
  }

  /// 로그아웃 시 이 기기에 남은 개인 기록을 지운다. 계정이 바뀌어도 로컬 DB는
  /// 그대로 남아 다음 사용자가 이전 사용자의 루틴과 운동을 보게 되기 때문이다.
  /// 기본 제공 종목(seed)은 남기고 사용자가 만든 종목만 지운다.
  Future<void> clearUserData() => transaction(() async {
    await delete(workoutSets).go();
    await delete(workoutSessions).go();
    await delete(routineItems).go();
    await delete(routines).go();
    await delete(personalRecords).go();
    await (delete(exercises)..where((row) => row.isCustom.equals(true))).go();
  });
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  return NativeDatabase(File(path.join(directory.path, 'heal_setlog.sqlite')));
});
