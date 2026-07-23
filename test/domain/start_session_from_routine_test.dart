import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/routine_item.dart';
import 'package:heal_setlog/domain/usecases/start_session_from_routine.dart';

void main() {
  RoutineItem item({
    required String ex,
    required int sets,
    int reps = 5,
    double weight = 100,
    int order = 0,
  }) => RoutineItem(
    id: 'i$order',
    routineId: 'r',
    exerciseId: ex,
    order: order,
    targetSets: sets,
    targetReps: reps,
    targetWeight: weight,
    updatedAt: DateTime(2026),
  );

  test('expands each item into targetSets drafts with mapped reps/weight', () {
    final drafts = plannedSetsFromRoutine([
      item(ex: 'a', sets: 3, reps: 5, weight: 100, order: 0),
      item(ex: 'b', sets: 2, reps: 10, weight: 60, order: 1),
    ]);

    expect(drafts, hasLength(5));
    expect(drafts.where((d) => d.exerciseId == 'a'), hasLength(3));
    expect(drafts.where((d) => d.exerciseId == 'b'), hasLength(2));

    final a = drafts.firstWhere((d) => d.exerciseId == 'a');
    expect(a.reps, 5);
    expect(a.weight, 100);
    final b = drafts.firstWhere((d) => d.exerciseId == 'b');
    expect(b.reps, 10);
    expect(b.weight, 60);
  });

  test('empty routine yields no drafts', () {
    expect(plannedSetsFromRoutine([]), isEmpty);
  });
}
