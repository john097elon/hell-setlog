import '../entities/workout_set.dart';

/// Returns completed, non-warmup, non-deleted set volume in kilograms.
double calculateSessionVolume(Iterable<WorkoutSet> sets) => sets
    .where((set) => set.isCompleted && !set.isWarmup && set.deletedAt == null)
    .fold(0, (volume, set) => volume + set.weight * set.reps);
