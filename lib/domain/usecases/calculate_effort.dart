import '../entities/discipline.dart';

/// 서로 다른 종목을 한 자에 놓기 위한 공통 단위.
///
/// 웨이트는 볼륨, 러닝은 거리, 주짓수는 시간으로 기록된다. 그대로는 비교할 수
/// 없어서 종목별 계수로 같은 점수(XP)로 환산한다. 기준은 "웨이트 볼륨 100kg = 1XP"
/// 이고 나머지는 체감이 비슷해지도록 맞췄다.
/// 5km 러닝 ≈ 50XP, 90분 주짓수(보통 강도) ≈ 90XP, 벤치 볼륨 5,000kg ≈ 50XP.
const double kgPerEffortPoint = 100;

/// 거리 1km당 점수. 종목마다 같은 거리의 힘듦이 다르다.
const Map<Discipline, double> _pointsPerKilometer = <Discipline, double>{
  Discipline.running: 10,
  Discipline.swimming: 40,
  Discipline.cycling: 3,
};

/// 시간으로 기록하는 종목의 분당 기본 점수.
const Map<Discipline, double> _pointsPerMinute = <Discipline, double>{
  Discipline.grappling: 1.2,
  Discipline.striking: 1.2,
  Discipline.mobility: 0.6,
  Discipline.other: 0.8,
};

/// 강도 1~5를 배수로 바꾼다. 3이 보통이다.
double intensityMultiplier(int? intensity) => switch (intensity) {
  1 => 0.6,
  2 => 0.8,
  4 => 1.3,
  5 => 1.6,
  _ => 1.0,
};

/// 기록 한 줄이 만들어 낸 점수.
///
/// 값이 없거나 음수면 0으로 본다. 종목에 맞지 않는 값은 무시한다.
/// 예를 들어 러닝에 무게가 들어와도 거리로만 계산한다.
double effortPoints({
  required Discipline discipline,
  double? weightKg,
  int? reps,
  double? distanceMeters,
  int? durationSeconds,
  int? intensity,
}) {
  switch (trackingModeOf(discipline)) {
    case TrackingMode.setsReps:
      final volume = (weightKg ?? 0) * (reps ?? 0);
      return volume <= 0 ? 0 : volume / kgPerEffortPoint;
    case TrackingMode.distanceDuration:
      final kilometers = (distanceMeters ?? 0) / 1000;
      if (kilometers <= 0) {
        // 거리를 안 적었으면 시간만으로도 인정한다.
        return _minutesOf(durationSeconds) * 0.8;
      }
      return kilometers * (_pointsPerKilometer[discipline] ?? 5);
    case TrackingMode.durationIntensity:
      final minutes = _minutesOf(durationSeconds);
      if (minutes <= 0) return 0;
      return minutes *
          (_pointsPerMinute[discipline] ?? 0.8) *
          intensityMultiplier(intensity);
  }
}

double _minutesOf(int? durationSeconds) {
  final seconds = durationSeconds ?? 0;
  return seconds <= 0 ? 0 : seconds / 60;
}
