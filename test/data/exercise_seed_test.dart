import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart';
import 'package:heal_setlog/data/repositories/exercise_repository_impl.dart';
import 'package:heal_setlog/data/local/seed/exercise_seed.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';

void main() {
  late AppDatabase database;
  late ExerciseRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ExerciseRepositoryImpl(database.exerciseDao);
  });
  tearDown(() => database.close());

  test('기존 60개 id를 유지하고 모든 새 갈래를 포함한다', () {
    final originalIds = List<String>.generate(
      60,
      (index) =>
          '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
    );

    expect(exerciseSeed.take(60).map((exercise) => exercise.id), originalIds);
    expect(exerciseSeed, hasLength(88));
    for (final discipline in Discipline.values.skip(1)) {
      expect(
        exerciseSeed.any((exercise) => exercise.discipline == discipline),
        isTrue,
        reason: discipline.name,
      );
    }
    expect(
      exerciseSeed.skip(60).every((exercise) => exercise.thumbnailUrl == null),
      isTrue,
    );
  });

  test('기본 종목의 갈래가 저장되고 다시 읽힌다', () async {
    await repository.ensureSeeded();
    final all = (await repository.getAll()).when(
      ok: (items) => items,
      err: (failure) => throw failure,
    );

    expect(all.length, exerciseSeed.length);
    for (final seeded in exerciseSeed) {
      final stored = all.firstWhere((item) => item.id == seeded.id);
      expect(stored.discipline, seeded.discipline, reason: seeded.nameKo);
    }
  });

  test('이미 종목이 있어도 새로 추가된 것만 채운다', () async {
    // 예전 버전에서 일부만 들어간 상태를 흉내 낸다.
    // 예전 버전에서 일부만 들어간 상태를 흉내 낸다.
    await database.exerciseDao.insertAll(<ExercisesCompanion>[
      ExercisesCompanion.insert(
        id: exerciseSeed.first.id,
        name: exerciseSeed.first.name,
        nameKo: exerciseSeed.first.nameKo,
        muscleGroup: exerciseSeed.first.muscleGroup.index,
        equipment: exerciseSeed.first.equipment.index,
      ),
    ]);

    await repository.ensureSeeded();

    final all = (await repository.getAll()).when(
      ok: (items) => items,
      err: (failure) => throw failure,
    );
    expect(all.length, exerciseSeed.length);
  });
}
