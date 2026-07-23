import '../../core/constants/stats.dart';

/// An Epley one-repetition maximum estimate.
class OneRepMax {
  const OneRepMax(this.value, {this.lowConfidence = false});

  final double value;
  final bool lowConfidence;
}

/// Epley: 1RM = weight * (1 + reps/30). Returns zero for invalid reps.
OneRepMax calculateOneRepMax(double weight, int reps) => reps <= 0
    ? const OneRepMax(0)
    : reps == 1
    ? OneRepMax(weight)
    : OneRepMax(
        weight * (1 + reps / kEpleyRepetitionDivisor),
        lowConfidence: reps > kOneRepMaxLowConfidenceReps,
      );
