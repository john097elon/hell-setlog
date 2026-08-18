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

/// Groups completed, non-warmup, non-deleted set volume by the day it was done.
///
/// 세션 시작일로 묶으면 자정을 넘긴 운동과 며칠 열어 둔 세션의 기록이 엉뚱한
/// 날짜에 쌓인다. 세트를 마친 시각이 있으면 그 날짜를 쓴다.
Map<DateTime, double> dailyVolume(
  Iterable<WorkoutSession> sessions,
  Iterable<WorkoutSet> sets, {
  int days = 7,
}) {
  final cutoff = _dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
  final sessionDates = <String, DateTime>{
    for (final session in sessions)
      if (session.deletedAt == null)
        session.id: _dateOnly(session.startedAt),
  };
  final volumes = <DateTime, double>{};
  for (final set in sets.where(_isWorkingSet)) {
    final at = set.completedAt ?? sessionDates[set.sessionId];
    if (at == null) continue;
    final date = _dateOnly(at);
    if (date.isBefore(cutoff)) continue;
    volumes.update(
      date,
      (volume) => volume + set.weight * set.reps,
      ifAbsent: () => set.weight * set.reps,
    );
  }
  return volumes;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
