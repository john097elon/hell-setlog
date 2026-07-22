import 'package:drift/drift.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../local/app_database.dart' as database;
import '../local/daos/exercise_dao.dart';
import '../local/seed/exercise_seed.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl(this._dao);

  final ExerciseDao _dao;

  /// Inserts the built-in exercises only when the local table is empty.
  Future<void> ensureSeeded() async {
    if ((await _dao.getAll()).isEmpty) {
      await _dao.insertAll(exerciseSeed.map(_toCompanion).toList());
    }
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

  database.ExercisesCompanion _toCompanion(Exercise exercise) => database.ExercisesCompanion.insert(
    id: exercise.id,
    name: exercise.name,
    nameKo: exercise.nameKo,
    muscleGroup: exercise.muscleGroup.index,
    equipment: exercise.equipment.index,
    isCustom: Value(exercise.isCustom),
    thumbnailUrl: Value(exercise.thumbnailUrl),
  );

  Exercise _toEntity(database.Exercise data) => Exercise(
    id: data.id,
    name: data.name,
    nameKo: data.nameKo,
    muscleGroup: MuscleGroup.values[data.muscleGroup],
    equipment: Equipment.values[data.equipment],
    isCustom: data.isCustom,
    thumbnailUrl: data.thumbnailUrl,
  );
}
