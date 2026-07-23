import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/routine.dart';
import '../entities/routine_item.dart';

abstract class RoutineRepository {
  Future<Result<Routine, Failure>> createRoutine({
    required String name,
    String? description,
  });
  Future<Result<List<Routine>, Failure>> getRoutines();
  Future<Result<Routine, Failure>> getRoutine(String id);
  Future<Result<Routine, Failure>> renameRoutine(
    String id, {
    required String name,
    String? description,
  });
  Future<Result<void, Failure>> deleteRoutine(String id);
  Future<Result<RoutineItem, Failure>> addItem({
    required String routineId,
    required String exerciseId,
    required int targetSets,
    required int targetReps,
    required double targetWeight,
  });
  Future<Result<RoutineItem, Failure>> updateItem(RoutineItem item);
  Future<Result<void, Failure>> removeItem(String itemId);
  Future<Result<List<RoutineItem>, Failure>> getItems(String routineId);
}
