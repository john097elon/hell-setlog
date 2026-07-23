import '../entities/exercise.dart';
import '../entities/workout_session.dart';
import '../entities/workout_set.dart';

bool _isWorkingSet(WorkoutSet set) =>
    set.isCompleted && !set.isWarmup && set.deletedAt == null;

/// Groups completed, non-warmup, non-deleted set volume by muscle group.
Map<MuscleGroup, double> bodyPartVolume(
  Iterable<WorkoutSet> sets,
  Map<String, MuscleGroup> exerciseMuscle,
) {
  final volumes = <MuscleGroup, double>{};
  for (final set in sets.where(_isWorkingSet)) {
    final muscle = exerciseMuscle[set.exerciseId];
    if (muscle != null) {
      volumes.update(
        muscle,
        (volume) => volume + set.weight * set.reps,
        ifAbsent: () => set.weight * set.reps,
      );
    }
  }
  return volumes;
}

/// Groups completed, non-warmup, non-deleted set volume by session date.
Map<DateTime, double> dailyVolume(
  Iterable<WorkoutSession> sessions,
  Iterable<WorkoutSet> sets, {
  int days = 7,
}) {
  final cutoff = _dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
  final sessionDates = {
    for (final session in sessions)
      if (session.deletedAt == null &&
          _dateOnly(
            session.startedAt,
          ).isAfter(cutoff.subtract(const Duration(days: 1))))
        session.id: _dateOnly(session.startedAt),
  };
  final volumes = <DateTime, double>{};
  for (final set in sets.where(_isWorkingSet)) {
    final date = sessionDates[set.sessionId];
    if (date != null) {
      volumes.update(
        date,
        (volume) => volume + set.weight * set.reps,
        ifAbsent: () => set.weight * set.reps,
      );
    }
  }
  return volumes;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
