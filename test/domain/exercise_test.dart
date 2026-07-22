import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';

void main() {
  test('Exercise retains required exercise metadata', () {
    const exercise = Exercise(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Bench Press',
      nameKo: '벤치프레스',
      muscleGroup: MuscleGroup.chest,
      equipment: Equipment.barbell,
    );

    expect(exercise.isCustom, isFalse);
    expect(exercise.thumbnailUrl, isNull);
  });
}
