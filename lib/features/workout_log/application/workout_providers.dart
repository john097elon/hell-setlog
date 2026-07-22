import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/workout_repository_impl.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_set.dart';
import '../../../domain/repositories/workout_repository.dart';
import '../../exercise_db/application/exercise_providers.dart';

part 'workout_providers.g.dart';

@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(WorkoutRepositoryRef ref) =>
    WorkoutRepositoryImpl(ref.watch(appDatabaseProvider).workoutDao);

@riverpod
Future<Result<WorkoutSession, Failure>> activeSession(ActiveSessionRef ref) =>
    ref.watch(workoutRepositoryProvider).getActiveSession();

@riverpod
Stream<List<WorkoutSet>> sessionSets(SessionSetsRef ref, String sessionId) =>
    ref.watch(workoutRepositoryProvider).watchSets(sessionId);
