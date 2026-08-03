import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/local/app_database.dart';
import 'package:heal_setlog/data/local/seed/exercise_seed.dart';
import 'package:heal_setlog/data/repositories/exercise_repository_impl.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';

void main() {
  late AppDatabase database;
  late ExerciseRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ExerciseRepositoryImpl(database.exerciseDao);
  });
  tearDown(() => database.close());

  test('목록에 없는 운동을 직접 만들 수 있다', () async {
    final created = (await repository.createCustom(
      nameKo: '카포에라',
      discipline: Discipline.striking,
    )).when(ok: (item) => item, err: (failure) => throw failure);

    expect(created.isCustom, isTrue);
    expect(created.discipline, Discipline.striking);

    final stored = (await repository.getById(created.id)).when(
      ok: (item) => item,
      err: (failure) => throw failure,
    );
    expect(stored.nameKo, '카포에라');
    expect(stored.discipline, Discipline.striking);
  });

  test('이름이 비면 만들지 않는다', () async {
    final result = await repository.createCustom(
      nameKo: '   ',
      discipline: Discipline.other,
    );

    expect(result.isOk, isFalse);
  });

  test('내가 만든 종목은 지울 수 있다', () async {
    final created = (await repository.createCustom(
      nameKo: '파쿠르',
      discipline: Discipline.other,
    )).when(ok: (item) => item, err: (failure) => throw failure);

    expect((await repository.deleteCustom(created.id)).isOk, isTrue);
    expect((await repository.getById(created.id)).isOk, isFalse);
  });

  test('기본 종목은 지울 수 없다', () async {
    await repository.ensureSeeded();

    // 지우면 그 종목으로 남긴 다른 기록까지 깨진다.
    final result = await repository.deleteCustom(exerciseSeed.first.id);

    expect(result.isOk, isFalse);
    expect((await repository.getById(exerciseSeed.first.id)).isOk, isTrue);
  });
}
