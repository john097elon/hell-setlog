import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart';
import 'package:heal_setlog/data/repositories/workout_repository_impl.dart';

/// 운동 종료를 누르지 않은 세션이 며칠씩 살아 있으면, 다음 운동이 거기에 붙고
/// 운동 시간도 며칠짜리로 찍힌다.
void main() {
  late AppDatabase database;
  late WorkoutRepositoryImpl workouts;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    workouts = WorkoutRepositoryImpl(database.workoutDao);
  });
  tearDown(() => database.close());

  Future<void> openSessionAt(DateTime startedAt, {DateTime? setAt}) async {
    await database
        .into(database.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: 'old',
            userId: 'me',
            startedAt: startedAt,
            updatedAt: startedAt,
          ),
        );
    if (setAt == null) return;
    await database
        .into(database.workoutSets)
        .insert(
          WorkoutSetsCompanion.insert(
            id: 'set-1',
            sessionId: 'old',
            exerciseId: 'e1',
            setIndex: 0,
            weight: 50,
            reps: 10,
            isCompleted: const Value(true),
            completedAt: Value(setAt),
            updatedAt: setAt,
          ),
        );
  }

  test('하루 지난 세션은 진행 중으로 보지 않는다', () async {
    // drift는 시각을 초 단위로 저장한다.
    final now = DateTime.now();
    final twoDaysAgo = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    ).subtract(const Duration(days: 2));
    await openSessionAt(
      twoDaysAgo,
      setAt: twoDaysAgo.add(const Duration(minutes: 40)),
    );

    final active = await workouts.getActiveSession();
    expect(active.isOk, isFalse);

    // 마지막 세트 시각으로 닫히고 볼륨도 채워진다.
    final stored = await database.workoutDao.getSessionById('old');
    expect(stored!.endedAt, twoDaysAgo.add(const Duration(minutes: 40)));
    expect(stored.totalVolume, 500);
  });

  test('닫힌 뒤 새로 시작하면 다른 세션이 된다', () async {
    await openSessionAt(DateTime.now().subtract(const Duration(days: 2)));

    final started = await workouts.startSession();
    final session = started.when(ok: (value) => value, err: (e) => throw e);

    expect(session.id, isNot('old'));
  });

  test('방금 시작한 세션은 그대로 이어 쓴다', () async {
    await openSessionAt(DateTime.now().subtract(const Duration(hours: 1)));

    final active = await workouts.getActiveSession();
    expect(active.when(ok: (value) => value.id, err: (_) => null), 'old');
  });
}
