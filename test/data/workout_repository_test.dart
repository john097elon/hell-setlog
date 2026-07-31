import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart'
    hide WorkoutSession, WorkoutSet;
import 'package:heal_setlog/data/repositories/workout_repository_impl.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';

void main() {
  late AppDatabase database;
  late WorkoutRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = WorkoutRepositoryImpl(database.workoutDao);
  });
  tearDown(() => database.close());

  test('starts and retrieves the latest active session', () async {
    final first = await repository.startSession();
    final second = await repository.startSession();
    final active = await repository.getActiveSession();

    expect(first.isOk, isTrue);
    expect(_session(active).id, _session(second).id);
  });

  test('assigns incrementing set indexes per exercise', () async {
    final session = _session(await repository.startSession());
    final sets = <WorkoutSet>[];
    for (var index = 0; index < 3; index++) {
      sets.add(
        _set(
          await repository.addSet(
            sessionId: session.id,
            exerciseId: 'bench',
            weight: 100,
            reps: 5,
          ),
        ),
      );
    }

    expect(sets.map((set) => set.setIndex), [0, 1, 2]);
  });

  test('completes and soft deletes sets from the stream', () async {
    final session = _session(await repository.startSession());
    final created = _set(
      await repository.addSet(
        sessionId: session.id,
        exerciseId: 'bench',
        weight: 100,
        reps: 5,
      ),
    );
    final completed = _set(await repository.completeSet(created.id));
    await repository.deleteSet(created.id);

    expect(completed.isCompleted, isTrue);
    expect(completed.completedAt, isNotNull);
    expect(await repository.watchSets(session.id).first, isEmpty);
  });

  test('삭제한 세트를 되살리면 목록에 다시 나타난다', () async {
    final session = _session(await repository.startSession());
    final created = _set(
      await repository.addSet(
        sessionId: session.id,
        exerciseId: 'bench',
        weight: 100,
        reps: 5,
      ),
    );
    await repository.deleteSet(created.id);
    expect(await repository.watchSets(session.id).first, isEmpty);

    // 스낵바의 되돌리기가 하는 일. deletedAt을 실제로 비워야 한다.
    await repository.updateSet(created.copyWith(clearDeletedAt: true));

    final restored = await repository.watchSets(session.id).first;
    expect(restored.length, 1);
    expect(restored.single.deletedAt, isNull);
  });

  test('ends with completed working-set volume', () async {
    final session = _session(await repository.startSession());
    final working = _set(
      await repository.addSet(
        sessionId: session.id,
        exerciseId: 'bench',
        weight: 100,
        reps: 5,
      ),
    );
    final warmup = _set(
      await repository.addSet(
        sessionId: session.id,
        exerciseId: 'bench',
        weight: 50,
        reps: 10,
        isWarmup: true,
      ),
    );
    await repository.completeSet(working.id);
    await repository.completeSet(warmup.id);
    final ended = _session(
      await repository.endSession(session.id, memo: 'done'),
    );

    expect(ended.totalVolume, 500);
    expect(ended.isActive, isFalse);
    expect(ended.memo, 'done');
  });

  test('migrates v1 without removing exercises', () async {
    await database.close();
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE exercises (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              name_ko TEXT NOT NULL,
              muscle_group INTEGER NOT NULL,
              equipment INTEGER NOT NULL,
              is_custom INTEGER NOT NULL DEFAULT 0,
              thumbnail_url TEXT
            )
          ''');
          raw.execute(
            "INSERT INTO exercises (id, name, name_ko, muscle_group, equipment) VALUES ('bench', 'Bench', '벤치', 0, 0)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );

    final exercises = await database.exerciseDao.getAll();
    await repository.startSession();

    expect(exercises.single.name, 'Bench');
  });
}

WorkoutSession _session(Object result) => (result as dynamic).when(
  ok: (WorkoutSession value) => value,
  err: (Object _) => throw StateError('expected a session'),
);

WorkoutSet _set(Object result) => (result as dynamic).when(
  ok: (WorkoutSet value) => value,
  err: (Object _) => throw StateError('expected a set'),
);
