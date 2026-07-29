import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';

void main() {
  group('calculateCharacterGrowth', () {
    test('zero volume starts every body part at level one', () {
      final growth = calculateCharacterGrowth(const {});

      expect(growth.levels[MuscleGroup.chest], 1);
      expect(growth.totalLevel, 6);
      expect(growth.evolutionStage, 0);
      expect(growth.nextEvolutionThreshold, 10);
      expect(growth.levelsUntilNextEvolution, 4);
    });

    test('uses the square-root boundary for body-part levels', () {
      expect(
        calculateCharacterGrowth(const {
          MuscleGroup.chest: 0,
        }).levels[MuscleGroup.chest],
        1,
      );
      expect(
        calculateCharacterGrowth(const {
          MuscleGroup.chest: 1,
        }).levels[MuscleGroup.chest],
        1,
      );
      expect(
        calculateCharacterGrowth(const {
          MuscleGroup.chest: 1000,
        }).levels[MuscleGroup.chest],
        2,
      );
    });

    for (final boundary in <int>[10, 25, 50, 100]) {
      test('evolves at total level $boundary', () {
        final growth = calculateCharacterGrowth({
          MuscleGroup.chest: (boundary - 6) * (boundary - 6) * 1000,
        });

        expect(growth.totalLevel, boundary);
        expect(
          growth.evolutionStage,
          <int>[10, 25, 50, 100].indexOf(boundary) + 1,
        );
        expect(
          growth.levelsUntilNextEvolution,
          boundary == 100 ? 0 : greaterThan(0),
        );
      });
    }
  });
}
