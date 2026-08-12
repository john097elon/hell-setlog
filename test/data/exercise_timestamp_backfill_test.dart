import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart';
import 'package:heal_setlog/data/repositories/exercise_repository_impl.dart';

/// 업그레이드로 붙은 created_at 열에는 SQL 기본값이 없다. 그 상태를 흉내 내어
/// 종목 목록이 죽지 않는지 본다.
void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    // 표를 만들어 두고, 문제의 두 열을 기본값 없는 형태로 되돌린다.
    await database.customStatement('DROP TABLE exercises');
    await database.customStatement('''
      CREATE TABLE exercises (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        name_ko TEXT NOT NULL,
        muscle_group INTEGER NOT NULL,
        equipment INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        thumbnail_url TEXT,
        user_id TEXT,
        created_at INTEGER,
        updated_at INTEGER,
        deleted_at INTEGER,
        discipline INTEGER NOT NULL DEFAULT 0,
        sync_status INTEGER NOT NULL DEFAULT 0
      )
    ''');
  });
  tearDown(() => database.close());

  test('시각을 채우지 않은 채 넣어도 종목을 읽을 수 있다', () async {
    final repository = ExerciseRepositoryImpl(database.exerciseDao);
    await repository.ensureSeeded();

    final blanks = await database
        .customSelect(
          'SELECT COUNT(*) AS n FROM exercises WHERE created_at IS NULL',
        )
        .getSingle();
    expect(blanks.data['n'], 0);

    final result = await repository.search();
    final items = result.when(ok: (value) => value, err: (e) => throw e);
    expect(items, isNotEmpty);
  });

  test('이미 비어 있는 행도 읽어낼 수 있게 채워진다', () async {
    await database.customStatement(
      "INSERT INTO exercises (id, name, name_ko, muscle_group, equipment) "
      "VALUES ('legacy', 'Legacy', '옛날 종목', 0, 0)",
    );

    await database.customStatement(
      "UPDATE exercises SET created_at = CAST(strftime('%s', "
      'CURRENT_TIMESTAMP) AS INTEGER) WHERE created_at IS NULL',
    );
    await database.customStatement(
      "UPDATE exercises SET updated_at = CAST(strftime('%s', "
      'CURRENT_TIMESTAMP) AS INTEGER) WHERE updated_at IS NULL',
    );

    final rows = await database.select(database.exercises).get();
    expect(rows.single.id, 'legacy');
  });
}
