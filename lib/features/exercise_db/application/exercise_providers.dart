import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/local/app_database.dart' hide Exercise;
import '../../../data/repositories/exercise_repository_impl.dart';
import '../../../domain/entities/discipline.dart';
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
    Discipline? discipline,
  }) async {
    final repository = await ref.watch(exerciseRepositoryProvider.future);
    final result = await repository.search(
      query: query,
      muscleGroup: muscleGroup,
      equipment: equipment,
    );
    return result.when(
      ok: (items) => Ok(
        discipline == null
            ? items
            : items
                  .where((exercise) => exercise.discipline == discipline)
                  .toList(growable: false),
      ),
      err: (failure) => Err(failure),
    );
  }
}

/// 최근에 기록한 순서대로 운동을 돌려준다. 매번 목록을 뒤지지 않게 하려는 것이라
/// 정렬 기준은 마지막으로 기록한 시각이다.
@riverpod
Future<List<Exercise>> recentExercises(
  RecentExercisesRef ref, {
  int limit = 8,
}) async {
  final database = ref.watch(appDatabaseProvider);
  final sets = await database.statsDao.allSets();
  final lastUsed = <String, DateTime>{};
  for (final set in sets) {
    if (set.deletedAt != null) continue;
    final at = set.completedAt ?? set.updatedAt;
    final known = lastUsed[set.exerciseId];
    if (known == null || at.isAfter(known)) lastUsed[set.exerciseId] = at;
  }
  if (lastUsed.isEmpty) return const <Exercise>[];
  final ids = lastUsed.keys.toList()
    ..sort((a, b) => lastUsed[b]!.compareTo(lastUsed[a]!));
  final trimmed = ids.take(limit);
  final repository = await ref.watch(exerciseRepositoryProvider.future);
  final found = <Exercise>[];
  for (final id in trimmed) {
    final result = await repository.getById(id);
    result.when(ok: found.add, err: (_) {});
  }
  return found;
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

@riverpod
CustomExerciseController customExerciseController(
  CustomExerciseControllerRef ref,
) =>
    CustomExerciseController(ref.watch(exerciseRepositoryProvider.future), ref);

/// Keeps custom exercise mutations and their cache refreshes out of widgets.
class CustomExerciseController {
  const CustomExerciseController(this._repository, this._ref);

  final Future<ExerciseRepository> _repository;
  final Ref _ref;

  Future<Result<Exercise, Failure>> create({
    required String nameKo,
    required Discipline discipline,
  }) async {
    final result = await (await _repository).createCustom(
      nameKo: nameKo,
      discipline: discipline,
    );
    if (result.isOk) _ref.invalidate(exerciseSearchProvider);
    return result;
  }

  Future<Result<void, Failure>> delete(String id) async {
    final result = await (await _repository).deleteCustom(id);
    if (result.isOk) {
      _ref
        ..invalidate(exerciseSearchProvider)
        ..invalidate(exerciseByIdProvider(id));
    }
    return result;
  }
}
