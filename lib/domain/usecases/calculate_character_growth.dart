import 'dart:math' as math;

import '../entities/exercise.dart';

const _trackedMuscleGroups = <MuscleGroup>[
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.shoulders,
  MuscleGroup.legs,
  MuscleGroup.arms,
  MuscleGroup.core,
];
const _evolutionThresholds = <int>[1, 10, 25, 50, 100];

/// Character growth derived from cumulative completed workout volume.
class CharacterGrowth {
  const CharacterGrowth({
    required this.levels,
    required this.totalLevel,
    required this.evolutionStage,
    required this.nextEvolutionThreshold,
    required this.levelsUntilNextEvolution,
  });

  final Map<MuscleGroup, int> levels;
  final int totalLevel;
  final int evolutionStage;
  final int? nextEvolutionThreshold;
  final int levelsUntilNextEvolution;
}

/// Calculates body-part levels and evolution from volume in kilograms.
CharacterGrowth calculateCharacterGrowth(Map<MuscleGroup, double> volumes) {
  final levels = <MuscleGroup, int>{
    for (final muscleGroup in _trackedMuscleGroups)
      muscleGroup: _levelForVolume(volumes[muscleGroup] ?? 0),
  };
  final totalLevel = levels.values.fold(0, (sum, level) => sum + level);
  final evolutionStage = _evolutionThresholds.lastIndexWhere(
    (threshold) => totalLevel >= threshold,
  );
  final nextEvolutionThreshold =
      evolutionStage == _evolutionThresholds.length - 1
      ? null
      : _evolutionThresholds[evolutionStage + 1];
  return CharacterGrowth(
    levels: levels,
    totalLevel: totalLevel,
    evolutionStage: evolutionStage,
    nextEvolutionThreshold: nextEvolutionThreshold,
    levelsUntilNextEvolution: nextEvolutionThreshold == null
        ? 0
        : nextEvolutionThreshold - totalLevel,
  );
}

int _levelForVolume(double volume) {
  if (volume <= 0) return 1;
  return (math.sqrt(volume / 1000).floor() + 1).clamp(1, 99);
}
