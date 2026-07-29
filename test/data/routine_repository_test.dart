import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/data/local/app_database.dart' hide Routine;
import 'package:heal_setlog/data/repositories/routine_repository_impl.dart';
import 'package:heal_setlog/domain/entities/routine.dart';

// ponytail: v2→v3 마이그레이션은 drift SchemaVerifier + 생성 스키마 파일이 필요해
// v0에서 유닛테스트 생략. 메모리 DB는 최신 스키마로 생성돼 repo 로직을 검증한다.
void main() {
  late AppDatabase database;
  late RoutineRepositoryImpl repo;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repo = RoutineRepositoryImpl(database.routineDao);
  });
  tearDown(() => database.close());

  Future<T> ok<T>(Future<Result<T, Failure>> f) async =>
      (await f).when(ok: (v) => v, err: (e) => throw StateError(e.message));

  test('createRoutine appears in getRoutines and getRoutine', () async {
    final r = await ok(repo.createRoutine(name: 'Push Day'));
    final list = await ok(repo.getRoutines());
    expect(list.map((e) => e.id), contains(r.id));
    expect((await ok(repo.getRoutine(r.id))).name, 'Push Day');
  });

  test('addItem assigns incrementing order and getItems is ordered', () async {
    final r = await ok(repo.createRoutine(name: 'R'));
    for (var i = 0; i < 3; i++) {
      await ok(
        repo.addItem(
          routineId: r.id,
          exerciseId: 'e$i',
          targetSets: 3,
          targetReps: 5,
          targetWeight: 50,
        ),
      );
    }
    final items = await ok(repo.getItems(r.id));
    expect(items.map((e) => e.order), [0, 1, 2]);
  });

  test('deleteRoutine soft-deletes routine and its items', () async {
    final r = await ok(repo.createRoutine(name: 'R'));
    await ok(
      repo.addItem(
        routineId: r.id,
        exerciseId: 'e',
        targetSets: 1,
        targetReps: 5,
        targetWeight: 20,
      ),
    );
    await ok(repo.deleteRoutine(r.id));
    expect(
      (await ok(repo.getRoutines())).map((e) => e.id),
      isNot(contains(r.id)),
    );
    expect(await ok(repo.getItems(r.id)), isEmpty);
  });

  test('removeItem drops it from getItems', () async {
    final r = await ok(repo.createRoutine(name: 'R'));
    final item = await ok(
      repo.addItem(
        routineId: r.id,
        exerciseId: 'e',
        targetSets: 1,
        targetReps: 5,
        targetWeight: 20,
      ),
    );
    await ok(repo.removeItem(item.id));
    expect(await ok(repo.getItems(r.id)), isEmpty);
  });

  test('getRoutine missing returns NotFoundFailure', () async {
    final res = await repo.getRoutine('nope');
    expect(res, isA<Err<Routine, Failure>>());
    expect(res.when(ok: (_) => null, err: (f) => f), isA<NotFoundFailure>());
  });
}
