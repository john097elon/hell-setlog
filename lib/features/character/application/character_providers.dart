import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/exercise.dart';
import '../../exercise_db/application/exercise_providers.dart';

final characterVolumesProvider = FutureProvider<Map<MuscleGroup, double>>((
  ref,
) async {
  final database = ref.watch(appDatabaseProvider);
  final sets = await database.statsDao.allSets();
  final exercises = await database.statsDao.exercisesForIds(
    sets.map((set) => set.exerciseId),
  );
  final muscles = <String, MuscleGroup>{
    for (final exercise in exercises)
      exercise.id: MuscleGroup.values[exercise.muscleGroup],
  };
  final volumes = <MuscleGroup, double>{};
  for (final set in sets) {
    final muscle = muscles[set.exerciseId];
    if (set.isCompleted && set.deletedAt == null && muscle != null) {
      volumes.update(
        muscle,
        (volume) => volume + set.weight * set.reps,
        ifAbsent: () => set.weight * set.reps,
      );
    }
  }
  return volumes;
});
