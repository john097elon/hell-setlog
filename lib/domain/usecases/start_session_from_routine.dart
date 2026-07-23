import '../entities/routine_item.dart';

class PlannedSetDraft {
  const PlannedSetDraft({
    required this.exerciseId,
    required this.reps,
    required this.weight,
    this.isWarmup = false,
  });
  final String exerciseId;
  final int reps;
  final double weight;
  final bool isWarmup;
}

List<PlannedSetDraft> plannedSetsFromRoutine(List<RoutineItem> items) => [
  for (final item in items)
    for (var i = 0; i < item.targetSets; i++)
      PlannedSetDraft(
        exerciseId: item.exerciseId,
        reps: item.targetReps,
        weight: item.targetWeight,
      ),
];
