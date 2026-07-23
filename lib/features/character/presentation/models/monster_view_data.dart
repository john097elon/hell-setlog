/// 몬스터 화면에서만 사용하는 정적 목업 데이터다.
enum MonsterBodyType { upper, lower, balanced }

/// 몬스터 화면의 부위별 목업 스탯 종류다.
enum MonsterStatKind { arm, leg, core, endure }

/// 부위별 목업 스탯 값이다.
class MonsterStatViewData {
  const MonsterStatViewData({
    required this.kind,
    required this.value,
    required this.maximum,
  });

  final MonsterStatKind kind;
  final int value;
  final int maximum;

  double get progress => value / maximum;
}

/// 몬스터 화면에서 P6 실데이터 연동 전까지 보여 줄 목업 뷰 데이터다.
class MonsterViewData {
  const MonsterViewData({
    required this.level,
    required this.bodyType,
    required this.stageAssetPath,
    required this.experience,
    required this.experienceMaximum,
    required this.stats,
  });

  final int level;
  final MonsterBodyType bodyType;
  final String stageAssetPath;
  final int experience;
  final int experienceMaximum;
  final List<MonsterStatViewData> stats;

  double get experienceProgress => experience / experienceMaximum;
}

const MonsterViewData monsterMockViewData = MonsterViewData(
  level: 50,
  bodyType: MonsterBodyType.balanced,
  stageAssetPath: 'assets/character/stage4_titannyang.png',
  experience: 820,
  experienceMaximum: 1000,
  stats: <MonsterStatViewData>[
    MonsterStatViewData(kind: MonsterStatKind.arm, value: 68, maximum: 100),
    MonsterStatViewData(kind: MonsterStatKind.leg, value: 84, maximum: 100),
    MonsterStatViewData(kind: MonsterStatKind.core, value: 61, maximum: 100),
    MonsterStatViewData(kind: MonsterStatKind.endure, value: 74, maximum: 100),
  ],
);
