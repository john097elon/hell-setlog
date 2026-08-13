import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/stats_repository_impl.dart';
import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/personal_record.dart';
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

/// Loads the personal records for one exercise.
@riverpod
Future<Result<List<PersonalRecord>, Failure>> personalRecords(
  PersonalRecordsRef ref,
  String exerciseId,
) => ref.watch(statsRepositoryProvider).personalRecords(exerciseId);

/// 이번 주에 실제로 운동한 날 수. 볼륨으로 세면 러닝·주짓수만 한 주가 0일이 된다.
@riverpod
Future<Result<int, Failure>> weeklyWorkoutDays(
  WeeklyWorkoutDaysRef ref, {
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
    final startedAt = <String, DateTime>{
      for (final session in sessions) session.id: session.startedAt,
    };
    final sets = await dao.setsForSessions(startedAt.keys);
    final dates = <DateTime>{};
    for (final set in sets) {
      if (!set.isCompleted || set.isWarmup || set.deletedAt != null) continue;
      final at = set.completedAt ?? startedAt[set.sessionId];
      if (at == null) continue;
      dates.add(DateTime(at.year, at.month, at.day));
    }
    return Ok(dates.length);
  } on Exception catch (error) {
    return Err(DatabaseFailure(error.toString()));
  }
}

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
