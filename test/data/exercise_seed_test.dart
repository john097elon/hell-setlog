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

  test('기존 88개 id를 유지하고 요청한 종목과 갈래를 포함한다', () {
    final originalIds = List<String>.generate(
      88,
      (index) =>
          '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
    );

    expect(exerciseSeed.take(88).map((exercise) => exercise.id), originalIds);
    expect(exerciseSeed, hasLength(119));
    expect(
      exerciseSeed.map((exercise) => exercise.nameKo).toSet(),
      hasLength(exerciseSeed.length),
    );
    for (final discipline in Discipline.values.skip(1)) {
      expect(
        exerciseSeed.any((exercise) => exercise.discipline == discipline),
        isTrue,
        reason: discipline.name,
      );
    }
    expect(
      exerciseSeed.skip(88).every((exercise) => exercise.thumbnailUrl == null),
      isTrue,
    );
    const expected = <String, Discipline>{
      '축구': Discipline.other,
      '농구': Discipline.other,
      '배구': Discipline.other,
      '야구': Discipline.other,
      '풋살': Discipline.other,
      '핸드볼': Discipline.other,
      '테니스': Discipline.other,
      '배드민턴': Discipline.other,
      '탁구': Discipline.other,
      '스쿼시': Discipline.other,
      '피클볼': Discipline.other,
      '검도': Discipline.striking,
      '합기도': Discipline.grappling,
      '크라브마가': Discipline.striking,
      '카포에라': Discipline.striking,
      '아이키도': Discipline.grappling,
      '스키': Discipline.other,
      '스노보드': Discipline.other,
      '아이스스케이팅': Discipline.other,
      '서핑': Discipline.other,
      '카약': Discipline.other,
      '조정': Discipline.other,
      '프리다이빙': Discipline.swimming,
      '수중 워킹': Discipline.swimming,
      '줌바': Discipline.other,
      '발레': Discipline.other,
      '폴댄스': Discipline.other,
      '사교댄스': Discipline.other,
      '힙합 댄스': Discipline.other,
      '크로스핏 WOD': Discipline.strength,
      '스트롱맨': Discipline.strength,
      '케틀벨 스윙': Discipline.strength,
      '파워리프팅 3종': Discipline.strength,
      '줄넘기': Discipline.running,
      '로잉 머신': Discipline.running,
      '스텝밀': Discipline.running,
      '일립티컬': Discipline.running,
      '걷기': Discipline.running,
    };
    for (final MapEntry(key: nameKo, value: discipline) in expected.entries) {
      final exercise = exerciseSeed.singleWhere(
        (item) => item.nameKo == nameKo,
      );
      expect(exercise.discipline, discipline, reason: nameKo);
    }
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
