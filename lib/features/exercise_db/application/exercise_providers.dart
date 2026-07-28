import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/local/app_database.dart' hide Exercise;
import '../../../data/repositories/exercise_repository_impl.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/repositories/exercise_repository.dart';

part 'exercise_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
}

/// Provides the local repository after its built-in exercise list is seeded.
@Riverpod(keepAlive: true)
Future<ExerciseRepository> exerciseRepository(ExerciseRepositoryRef ref) async {
  final repository = ExerciseRepositoryImpl(
    ref.watch(appDatabaseProvider).exerciseDao,
  );
  await repository.ensureSeeded();
  return repository;
}

/// Holds the result of a searchable, filterable exercise query.
@riverpod
class ExerciseSearch extends _$ExerciseSearch {
  @override
  Future<Result<List<Exercise>, Failure>> build({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  }) async {
    final repository = await ref.watch(exerciseRepositoryProvider.future);
    return repository.search(
      query: query,
      muscleGroup: muscleGroup,
      equipment: equipment,
    );
  }
}

/// Loads the full exercise metadata used outside the exercise picker.
@riverpod
Future<Result<Exercise, Failure>> exerciseById(
  ExerciseByIdRef ref,
  String id,
) async {
  final repository = await ref.watch(exerciseRepositoryProvider.future);
  return repository.getById(id);
}
