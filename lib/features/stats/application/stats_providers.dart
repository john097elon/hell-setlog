import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/stats_repository_impl.dart';
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
