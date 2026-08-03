import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../local/app_database.dart' as database;
import '../local/daos/exercise_dao.dart';
import '../local/seed/exercise_seed.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl(this._dao);

  final ExerciseDao _dao;
  static const Uuid _uuid = Uuid();

  /// 기본 종목 중 아직 없는 것만 넣는다.
  ///
  /// 예전에는 표가 비었을 때만 넣어서, 이미 쓰던 사람에게는 새로 추가한 종목이
  /// 영영 보이지 않았다. 사용자가 만든 종목과 기록은 건드리지 않는다.
  Future<void> ensureSeeded() async {
    final existing = (await _dao.getAll()).map((item) => item.id).toSet();
    final missing = exerciseSeed
        .where((exercise) => !existing.contains(exercise.id))
        .map(_toCompanion)
        .toList(growable: false);
    if (missing.isEmpty) return;
    await _dao.insertAll(missing);
  }

  @override
  Future<Result<List<Exercise>, Failure>> getAll() async {
    try {
      return Ok((await _dao.getAll()).map(_toEntity).toList());
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<List<Exercise>, Failure>> search({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  }) async {
    try {
      final exercises = await _dao.searchExercises(
        query: query,
        muscleGroup: muscleGroup,
        equipment: equipment,
      );
      return Ok(exercises.map(_toEntity).toList());
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Exercise, Failure>> getById(String id) async {
    try {
      final exercise = await _dao.getById(id);
      return exercise == null
          ? const Err(NotFoundFailure())
          : Ok(_toEntity(exercise));
    } on Exception catch (error) {
      return Err(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Exercise, Failure>> createCustom({
    required String nameKo,
    required Discipline discipline,
    MuscleGroup muscleGroup = MuscleGroup.fullBody,
    Equipment equipment = Equipment.other,
  }) async {
    final name = nameKo.trim();
    if (name.isEmpty) return const Err(DatabaseFailure('종목 이름을 입력해 주세요'));
    try {
      final exercise = Exercise(
        id: _uuid.v4(),
        name: name,
        nameKo: name,
        muscleGroup: muscleGroup,
        equipment: equipment,
        discipline: discipline,
        isCustom: true,
      );
      await _dao.insertAll(<database.ExercisesCompanion>[
        _toCompanion(exercise),
      ]);
      return Ok(exercise);
    } on Exception catch (error) {
      return Err(DatabaseFailure('종목을 만들지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<void, Failure>> deleteCustom(String id) async {
    try {
      final stored = await _dao.getById(id);
      if (stored == null) return const Err(NotFoundFailure());
      // 기본 제공 종목은 지우면 다른 사람 기록까지 깨진다.
      if (!stored.isCustom) {
        return const Err(DatabaseFailure('기본 종목은 지울 수 없습니다'));
      }
      await _dao.deleteById(id);
      return const Ok(null);
    } on Exception catch (error) {
      return Err(DatabaseFailure('종목을 지우지 못했습니다: $error'));
    }
  }

  database.ExercisesCompanion _toCompanion(Exercise exercise) =>
      database.ExercisesCompanion.insert(
        id: exercise.id,
        name: exercise.name,
        nameKo: exercise.nameKo,
        muscleGroup: exercise.muscleGroup.index,
        equipment: exercise.equipment.index,
        discipline: Value(exercise.discipline.index),
        isCustom: Value(exercise.isCustom),
        thumbnailUrl: Value(exercise.thumbnailUrl),
      );

  Exercise _toEntity(database.Exercise data) => Exercise(
    id: data.id,
    name: data.name,
    nameKo: data.nameKo,
    muscleGroup: MuscleGroup.values[data.muscleGroup],
    equipment: Equipment.values[data.equipment],
    discipline: Discipline.values[data.discipline],
    isCustom: data.isCustom,
    thumbnailUrl: data.thumbnailUrl,
  );
}
