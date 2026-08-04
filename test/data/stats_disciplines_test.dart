import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart';
import 'package:heal_setlog/data/repositories/stats_repository_impl.dart';
import 'package:heal_setlog/data/repositories/workout_repository_impl.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/personal_record.dart';

/// 헬스 외 종목이 들어와도 통계가 제대로 나오는지 실제 DB로 확인한다.
void main() {
  late AppDatabase database;
  late StatsRepositoryImpl stats;
  late WorkoutRepositoryImpl workouts;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    stats = StatsRepositoryImpl(database.statsDao);
    workouts = WorkoutRepositoryImpl(database.workoutDao);
    await database.exerciseDao.insertAll(<ExercisesCompanion>[
      ExercisesCompanion.insert(
        id: 'bench',
        name: 'Bench',
        nameKo: '벤치',
        muscleGroup: MuscleGroup.chest.index,
        equipment: Equipment.barbell.index,
        discipline: Value(Discipline.strength.index),
      ),
      ExercisesCompanion.insert(
        id: 'run',
        name: 'Run',
        nameKo: '러닝',
        muscleGroup: MuscleGroup.fullBody.index,
        equipment: Equipment.bodyweight.index,
        discipline: Value(Discipline.running.index),
      ),
    ]);
  });
  tearDown(() => database.close());

  Future<String> startSession() async {
    final result = await workouts.startSession();
    return result.when(ok: (session) => session.id, err: (e) => throw e);
  }

  Future<void> addCompleted(
    String sessionId,
    String exerciseId, {
    double weight = 0,
    int reps = 0,
    double? distanceMeters,
    int? durationSeconds,
    bool isWarmup = false,
  }) async {
    final added = await workouts.addSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
      isWarmup: isWarmup,
    );
    final set = added.when(ok: (value) => value, err: (e) => throw e);
    final updated = set.copyWith(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
    await workouts.updateSet(updated);
    await workouts.completeSet(set.id);
  }

  test('웨이트 볼륨이 날짜별로 집계된다', () async {
    final session = await startSession();
    await addCompleted(session, 'bench', weight: 60, reps: 10);
    await addCompleted(session, 'bench', weight: 60, reps: 5);
    // 준비 세트는 빠져야 한다.
    await addCompleted(session, 'bench', weight: 40, reps: 10, isWarmup: true);

    final volumes = (await stats.weeklyVolume()).when(
      ok: (value) => value,
      err: (e) => throw e,
    );
    final total = volumes.values.fold<double>(0, (sum, value) => sum + value);

    expect(total, 900);
  });

  test('러닝만 한 주에도 종목별 기록 수는 잡힌다', () async {
    final session = await startSession();
    await addCompleted(
      session,
      'run',
      distanceMeters: 5000,
      durationSeconds: 1500,
    );

    final volumes = (await stats.weeklyVolume()).when(
      ok: (value) => value,
      err: (e) => throw e,
    );
    // 러닝은 무게가 없어 볼륨은 0이다. 이것만 보면 화면이 빈 것처럼 보인다.
    expect(volumes.values.fold<double>(0, (sum, value) => sum + value), 0);

    final sets = await database.statsDao.setsForSessions(<String>[session]);
    expect(sets.where((set) => set.isCompleted).length, 1);
    expect(sets.first.distanceMeters, 5000);
    expect(sets.first.durationSeconds, 1500);
  });

  test('종목별 개인 기록이 종목에 맞게 만들어진다', () async {
    final session = await startSession();
    await addCompleted(session, 'bench', weight: 100, reps: 5);
    await addCompleted(
      session,
      'run',
      distanceMeters: 5000,
      durationSeconds: 1500,
    );

    final records = (await stats.updateRecordsForSession(session)).when(
      ok: (value) => value,
      err: (e) => throw e,
    );
    final benchTypes = records
        .where((record) => record.exerciseId == 'bench')
        .map((record) => record.type)
        .toSet();
    final runTypes = records
        .where((record) => record.exerciseId == 'run')
        .map((record) => record.type)
        .toSet();

    expect(benchTypes, <PrType>{PrType.oneRm, PrType.volume, PrType.reps});
    // 러닝에 1RM은 의미가 없다.
    expect(runTypes, <PrType>{PrType.distance, PrType.duration, PrType.speed});

    final speed = records.firstWhere((record) => record.type == PrType.speed);
    expect(speed.value, closeTo(5000 / 1500, 0.001));
  });

  test('근육군 비중은 웨이트 기록만 센다', () async {
    final session = await startSession();
    await addCompleted(session, 'bench', weight: 50, reps: 10);
    await addCompleted(
      session,
      'run',
      distanceMeters: 3000,
      durationSeconds: 900,
    );

    final split = (await stats.bodyPartSplit()).when(
      ok: (value) => value,
      err: (e) => throw e,
    );

    expect(split[MuscleGroup.chest], 500);
    // 러닝은 무게가 0이라 비중에 들어가더라도 0이어야 한다.
    expect(split[MuscleGroup.fullBody] ?? 0, 0);
  });
}
