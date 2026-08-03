import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/stats_repository_impl.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/repositories/stats_repository.dart';
import '../../exercise_db/application/exercise_providers.dart';

part 'stats_providers.g.dart';

@Riverpod(keepAlive: true)
StatsRepository statsRepository(StatsRepositoryRef ref) =>
    StatsRepositoryImpl(ref.watch(appDatabaseProvider).statsDao);

@riverpod
Future<Result<Map<DateTime, double>, Failure>> weeklyVolume(
  WeeklyVolumeRef ref, {
  int days = 7,
}) => ref.watch(statsRepositoryProvider).weeklyVolume(days: days);

@riverpod
Future<Result<Map<MuscleGroup, double>, Failure>> bodyPartSplit(
  BodyPartSplitRef ref, {
  int days = 30,
}) => ref.watch(statsRepositoryProvider).bodyPartSplit(days: days);

/// Counts completed weekly records by discipline, including non-weight sports.
@riverpod
Future<Result<Map<Discipline, int>, Failure>> weeklyDisciplineCounts(
  WeeklyDisciplineCountsRef ref, {
  int days = 7,
}) async {
  try {
    final dao = ref.watch(appDatabaseProvider).statsDao;
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final sessions = await dao.sessionsSince(cutoff);
    final sets = (await dao.setsForSessions(sessions.map((item) => item.id)))
        .where(
          (item) =>
              item.isCompleted && !item.isWarmup && item.deletedAt == null,
        )
        .toList(growable: false);
    final exercises = await dao.exercisesForIds(
      sets.map((item) => item.exerciseId),
    );
    final disciplines = <String, Discipline>{
      for (final exercise in exercises)
        if (exercise.discipline >= 0 &&
            exercise.discipline < Discipline.values.length)
          exercise.id: Discipline.values[exercise.discipline],
    };
    final counts = <Discipline, int>{};
    for (final set in sets) {
      final discipline = disciplines[set.exerciseId];
      if (discipline != null) {
        counts.update(discipline, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return Ok(counts);
  } on Exception catch (error) {
    return Err(DatabaseFailure(error.toString()));
  }
}
