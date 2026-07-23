import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/routine_repository_impl.dart';
import '../../../domain/entities/routine.dart';
import '../../../domain/entities/routine_item.dart';
import '../../../domain/repositories/routine_repository.dart';
import '../../exercise_db/application/exercise_providers.dart';
part 'routine_providers.g.dart';

@Riverpod(keepAlive: true)
RoutineRepository routineRepository(RoutineRepositoryRef ref) =>
    RoutineRepositoryImpl(ref.watch(appDatabaseProvider).routineDao);
@riverpod
Future<Result<List<Routine>, Failure>> routines(RoutinesRef ref) =>
    ref.watch(routineRepositoryProvider).getRoutines();

@riverpod
Future<Result<List<RoutineItem>, Failure>> routineItems(
  RoutineItemsRef ref,
  String routineId,
) => ref.watch(routineRepositoryProvider).getItems(routineId);
