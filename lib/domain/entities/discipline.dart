/// 운동 갈래. 헬스만이 아니라 세상의 운동을 담기 위한 분류다.
enum Discipline {
  /// 웨이트 트레이닝.
  strength,

  /// 달리기.
  running,

  /// 수영.
  swimming,

  /// 자전거.
  cycling,

  /// 주짓수·유도·레슬링처럼 잡고 하는 무술.
  grappling,

  /// 킥복싱·복싱·무에타이처럼 치고 하는 무술.
  striking,

  /// 요가·필라테스·스트레칭.
  mobility,

  /// 위에 없는 활동.
  other,
}

/// 종목마다 기록할 값이 다르다. 입력판은 이 값에 따라 바뀐다.
enum TrackingMode {
  /// 무게 × 횟수. 웨이트.
  setsReps,

  /// 거리 + 시간. 달리기·수영·자전거.
  distanceDuration,

  /// 시간 + 강도. 무술·요가처럼 거리도 무게도 없는 활동.
  durationIntensity,
}

/// 종목이 어떤 방식으로 기록되는지.
TrackingMode trackingModeOf(Discipline discipline) => switch (discipline) {
  Discipline.strength => TrackingMode.setsReps,
  Discipline.running ||
  Discipline.swimming ||
  Discipline.cycling => TrackingMode.distanceDuration,
  Discipline.grappling ||
  Discipline.striking ||
  Discipline.mobility ||
  Discipline.other => TrackingMode.durationIntensity,
};

/// 저장된 문자열을 종목으로 되돌린다. 모르는 값이면 웨이트로 본다.
Discipline disciplineFrom(String? raw) => switch (raw) {
  'running' => Discipline.running,
  'swimming' => Discipline.swimming,
  'cycling' => Discipline.cycling,
  'grappling' => Discipline.grappling,
  'striking' => Discipline.striking,
  'mobility' => Discipline.mobility,
  'other' => Discipline.other,
  _ => Discipline.strength,
};

String disciplineKey(Discipline discipline) => discipline.name;

/// 화면에 쓰는 종목 이름.
String disciplineLabel(Discipline discipline) => switch (discipline) {
  Discipline.strength => '웨이트',
  Discipline.running => '러닝',
  Discipline.swimming => '수영',
  Discipline.cycling => '사이클',
  Discipline.grappling => '그래플링',
  Discipline.striking => '입식 격투',
  Discipline.mobility => '유연성',
  Discipline.other => '기타',
};
