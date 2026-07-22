import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/data/local/app_database.dart' hide Exercise;
import 'package:heal_setlog/data/repositories/exercise_repository_impl.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';

void main() {
  late AppDatabase database;
  late ExerciseRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ExerciseRepositoryImpl(database.exerciseDao);
    await repository.ensureSeeded();
  });

  tearDown(() => database.close());

  test('seeds 60 exercises with Korean names', () async {
    final result = await repository.getAll();

    final exercises = result.when(ok: (value) => value, err: (_) => <Exercise>[]);
    expect(exercises, hasLength(60));
    expect(exercises.every((exercise) => exercise.nameKo.isNotEmpty), isTrue);
  });

  test('searches Korean and English names without case sensitivity', () async {
    final korean = await repository.search(query: '벤치');
    final english = await repository.search(query: 'bench');

    expect(_names(korean), contains('Bench Press'));
    expect(_names(english), contains('Bench Press'));
  });

  test('filters by muscle group and equipment together', () async {
    final legs = await repository.search(muscleGroup: MuscleGroup.legs);
    final bench = await repository.search(
      query: '벤치',
      equipment: Equipment.barbell,
    );

    final legExercises = legs.when(ok: (value) => value, err: (_) => <Exercise>[]);
    expect(legExercises.every((exercise) => exercise.muscleGroup == MuscleGroup.legs), isTrue);
    expect(_names(bench), contains('Bench Press'));
  });

  test('search without filters returns all exercises', () async {
    final result = await repository.search();

    expect(_names(result), hasLength(60));
  });

  test('missing id returns NotFoundFailure', () async {
    final result = await repository.getById('missing-id');

    expect(result, isA<Err<Exercise, Failure>>());
    expect(
      result.when(ok: (_) => null, err: (failure) => failure),
      isA<NotFoundFailure>(),
    );
  });
}

List<String> _names(Result<List<Exercise>, Failure> result) =>
    result.when(ok: (value) => value.map((exercise) => exercise.name).toList(), err: (_) => []);
