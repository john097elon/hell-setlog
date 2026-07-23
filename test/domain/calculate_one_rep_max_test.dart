import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/usecases/calculate_one_rep_max.dart';

void main() {
  test('calculates Epley one rep max and confidence boundaries', () {
    expect(calculateOneRepMax(100, 5).value, closeTo(116.7, 0.1));
    expect(calculateOneRepMax(100, 1).value, 100);
    expect(calculateOneRepMax(100, 13).lowConfidence, isTrue);
    expect(calculateOneRepMax(100, 0).value, 0);
  });
}
