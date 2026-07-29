import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/routine.dart';
import '../../../domain/entities/routine_item.dart';
import '../../../domain/repositories/routine_repository.dart';
import 'routine_providers.dart';

part 'routine_editor_controller.g.dart';

@riverpod
RoutineEditorController routineEditorController(
  RoutineEditorControllerRef ref,
) => RoutineEditorController(ref.watch(routineRepositoryProvider), ref);

/// Coordinates routine editing while keeping repository calls out of widgets.
class RoutineEditorController {
  RoutineEditorController(this._repository, this._ref);

  final RoutineRepository _repository;
  final Ref _ref;

  Future<Result<Routine, Failure>> saveRoutine({
    String? routineId,
    required String name,
  }) async {
    final result = routineId == null
        ? await _repository.createRoutine(name: name)
        : await _repository.renameRoutine(routineId, name: name);
    _ref.invalidate(routinesProvider);
    return result;
  }

  Future<Result<RoutineItem, Failure>> addItem({
    required String routineId,
    required String exerciseId,
    required int targetSets,
    required int targetReps,
    required double targetWeight,
  }) async {
    final result = await _repository.addItem(
      routineId: routineId,
      exerciseId: exerciseId,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
    );
    _ref.invalidate(routineItemsProvider(routineId));
    return result;
  }

  Future<Result<RoutineItem, Failure>> updateItem(RoutineItem item) async {
    final result = await _repository.updateItem(item);
    _ref.invalidate(routineItemsProvider(item.routineId));
    return result;
  }

  Future<Result<void, Failure>> removeItem(RoutineItem item) async {
    final result = await _repository.removeItem(item.id);
    _ref.invalidate(routineItemsProvider(item.routineId));
    return result;
  }

  Future<Result<void, Failure>> deleteRoutine(String routineId) async {
    final result = await _repository.deleteRoutine(routineId);
    _ref.invalidate(routinesProvider);
    return result;
  }
}
