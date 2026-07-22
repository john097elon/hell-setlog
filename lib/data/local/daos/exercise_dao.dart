import 'package:drift/drift.dart';

import '../../../domain/entities/exercise.dart' as domain;
import '../app_database.dart';
import '../tables/exercises_table.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Future<List<Exercise>> getAll() => (select(
    exercises,
  )..orderBy([(table) => OrderingTerm.asc(table.nameKo)])).get();

  Future<List<Exercise>> searchExercises({
    String? query,
    domain.MuscleGroup? muscleGroup,
    domain.Equipment? equipment,
  }) {
    final statement = select(exercises);
    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      final pattern = '%$normalizedQuery%';
      statement.where(
        (table) =>
            table.name.lower().like(pattern) |
            table.nameKo.lower().like(pattern),
      );
    }
    if (muscleGroup != null) {
      statement.where((table) => table.muscleGroup.equals(muscleGroup.index));
    }
    if (equipment != null) {
      statement.where((table) => table.equipment.equals(equipment.index));
    }
    statement.orderBy([(table) => OrderingTerm.asc(table.nameKo)]);
    return statement.get();
  }

  Future<Exercise?> getById(String id) => (select(
    exercises,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<void> insertAll(List<ExercisesCompanion> values) =>
      batch((batch) => batch.insertAll(exercises, values));
}
