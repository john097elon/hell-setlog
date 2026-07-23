import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../exercise_db/application/exercise_providers.dart';

part 'exercise_name_provider.g.dart';

/// Resolves an exercise identifier to display text outside presentation code.
@riverpod
Future<String?> exerciseName(ExerciseNameRef ref, String exerciseId) async {
  final repository = await ref.watch(exerciseRepositoryProvider.future);
  final result = await repository.getById(exerciseId);
  return result.when(ok: (exercise) => exercise.nameKo, err: (_) => null);
}
