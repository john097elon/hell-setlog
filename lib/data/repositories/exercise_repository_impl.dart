import 'package:drift/drift.dart';

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
