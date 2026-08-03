import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/usecases/calculate_effort.dart';

void main() {
  test('종목마다 기록 방식이 다르다', () {
    expect(trackingModeOf(Discipline.strength), TrackingMode.setsReps);
    expect(trackingModeOf(Discipline.running), TrackingMode.distanceDuration);
    expect(trackingModeOf(Discipline.swimming), TrackingMode.distanceDuration);
    expect(
      trackingModeOf(Discipline.grappling),
      TrackingMode.durationIntensity,
    );
    expect(trackingModeOf(Discipline.mobility), TrackingMode.durationIntensity);
  });

  test('웨이트는 볼륨 100kg마다 1점이다', () {
    expect(
      effortPoints(discipline: Discipline.strength, weightKg: 60, reps: 10),
      6,
    );
    // 러닝 값이 섞여 들어와도 웨이트는 볼륨만 본다.
    expect(
      effortPoints(
        discipline: Discipline.strength,
        weightKg: 60,
        reps: 10,
        distanceMeters: 5000,
      ),
      6,
    );
  });

  test('거리 종목은 종목별 계수로 환산한다', () {
    // 5km 러닝은 벤치 볼륨 5,000kg과 비슷한 점수를 받는다.
    expect(
      effortPoints(discipline: Discipline.running, distanceMeters: 5000),
      50,
    );
    expect(
      effortPoints(discipline: Discipline.swimming, distanceMeters: 1000),
      40,
    );
    expect(
      effortPoints(discipline: Discipline.cycling, distanceMeters: 20000),
      60,
    );
  });

  test('거리를 안 적었으면 시간만으로도 인정한다', () {
    expect(
      effortPoints(discipline: Discipline.running, durationSeconds: 1800),
      closeTo(24, 0.001),
    );
  });

  test('시간 종목은 강도가 점수를 바꾼다', () {
    // 90분 그래플링, 보통 강도.
    expect(
      effortPoints(
        discipline: Discipline.grappling,
        durationSeconds: 5400,
        intensity: 3,
      ),
      closeTo(108, 0.001),
    );
    // 같은 시간이라도 강도가 낮으면 적게 받는다.
    expect(
      effortPoints(
        discipline: Discipline.grappling,
        durationSeconds: 5400,
        intensity: 1,
      ),
      closeTo(64.8, 0.001),
    );
  });

  test('값이 없거나 음수면 0점이다', () {
    expect(effortPoints(discipline: Discipline.strength), 0);
    expect(
      effortPoints(discipline: Discipline.strength, weightKg: -10, reps: 5),
      0,
    );
    expect(effortPoints(discipline: Discipline.running), 0);
    expect(
      effortPoints(discipline: Discipline.grappling, durationSeconds: 0),
      0,
    );
  });
}
