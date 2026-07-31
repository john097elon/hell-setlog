import 'dart:math' as math;

import '../entities/exercise.dart';

/// 캐릭터가 추적하는 부위. 전신/기타는 여기에 나눠 담지 않는다.
const List<MuscleGroup> trackedMuscleGroups = <MuscleGroup>[
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.shoulders,
  MuscleGroup.legs,
  MuscleGroup.arms,
  MuscleGroup.core,
];

/// 볼륨 100kg당 1XP. 벤치 60kg × 10회 = 600kg = 6XP.
const double _kgPerXp = 100;

/// 레벨 n에서 n+1로 가는 데 필요한 XP. 레벨이 오를수록 완만하게 늘어난다.
const int _baseXpPerLevel = 40;

/// 진화 단계에 필요한 합산 레벨. 5단계 아트가 있어 다섯 구간이다.
const List<int> evolutionThresholds = <int>[0, 12, 30, 60, 120];

/// 몸 균형. 상체·하체 볼륨 비율로 정한다.
enum BodyBalance { upper, lower, balanced }

/// 한 부위의 성장 상태.
class MuscleGrowth {
  const MuscleGrowth({
    required this.group,
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  final MuscleGroup group;
  final int xp;
  final int level;

  /// 현재 레벨에서 쌓은 XP.
  final int xpIntoLevel;

  /// 다음 레벨까지 필요한 XP. 최고 레벨이면 0.
  final int xpForNextLevel;

  double get progress =>
      xpForNextLevel == 0 ? 1 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);
}

/// 캐릭터 전체 성장 상태.
class CharacterGrowth {
  const CharacterGrowth({
    required this.muscles,
    required this.totalXp,
    required this.totalLevel,
    required this.evolutionStage,
    required this.balance,
    required this.weeklyXp,
    this.nextEvolutionThreshold,
  });

  final List<MuscleGrowth> muscles;
  final int totalXp;
  final int totalLevel;

  /// 0부터 시작하는 진화 단계 인덱스.
  final int evolutionStage;
  final BodyBalance balance;

  /// 최근 7일 동안 얻은 XP. 지금 성장 중인지 보여준다.
  final int weeklyXp;
  final int? nextEvolutionThreshold;

  bool get isMaxStage => nextEvolutionThreshold == null;

  int get levelsUntilNextEvolution =>
      nextEvolutionThreshold == null ? 0 : nextEvolutionThreshold! - totalLevel;

  /// 현재 단계에서 다음 단계까지의 진행률.
  double get evolutionProgress {
    if (nextEvolutionThreshold == null) return 1;
    final start = evolutionThresholds[evolutionStage];
    final span = nextEvolutionThreshold! - start;
    if (span <= 0) return 1;
    return ((totalLevel - start) / span).clamp(0.0, 1.0);
  }

  Map<MuscleGroup, int> get levels => <MuscleGroup, int>{
    for (final muscle in muscles) muscle.group: muscle.level,
  };
}

/// 누적 볼륨(kg)에서 캐릭터 성장을 계산한다.
///
/// [volumes]는 전체 기간 누적, [weeklyVolumes]는 최근 7일치다.
CharacterGrowth calculateCharacterGrowth(
  Map<MuscleGroup, double> volumes, {
  Map<MuscleGroup, double> weeklyVolumes = const <MuscleGroup, double>{},
}) {
  final muscles = <MuscleGrowth>[
    for (final group in trackedMuscleGroups)
      _growthFor(group, volumes[group] ?? 0),
  ];
  final totalXp = muscles.fold(0, (sum, muscle) => sum + muscle.xp);
  final totalLevel = muscles.fold(0, (sum, muscle) => sum + muscle.level);
  final stage = evolutionStageForLevel(totalLevel);
  return CharacterGrowth(
    muscles: muscles,
    totalXp: totalXp,
    totalLevel: totalLevel,
    evolutionStage: stage,
    balance: _balanceOf(volumes),
    weeklyXp: xpForVolume(
      weeklyVolumes.values.fold(0, (sum, volume) => sum + volume),
    ),
    nextEvolutionThreshold: stage == evolutionThresholds.length - 1
        ? null
        : evolutionThresholds[stage + 1],
  );
}

/// 볼륨을 XP로 바꾼다. 음수 볼륨은 0으로 본다.
int xpForVolume(double volumeKg) =>
    volumeKg <= 0 ? 0 : (volumeKg / _kgPerXp).floor();

/// 레벨 [level]에서 다음 레벨까지 필요한 XP.
int xpToReachNextLevel(int level) => _baseXpPerLevel * level;

/// 합산 레벨에 해당하는 진화 단계.
int evolutionStageForLevel(int totalLevel) => math.max(
  0,
  evolutionThresholds.lastIndexWhere((threshold) => totalLevel >= threshold),
);

MuscleGrowth _growthFor(MuscleGroup group, double volume) {
  final xp = xpForVolume(volume);
  var remaining = xp;
  var level = 1;
  // 레벨 1→2는 40XP, 2→3은 80XP처럼 필요량이 늘어난다.
  while (level < 99 && remaining >= xpToReachNextLevel(level)) {
    remaining -= xpToReachNextLevel(level);
    level++;
  }
  return MuscleGrowth(
    group: group,
    xp: xp,
    level: level,
    xpIntoLevel: remaining,
    xpForNextLevel: level >= 99 ? 0 : xpToReachNextLevel(level),
  );
}

BodyBalance _balanceOf(Map<MuscleGroup, double> volumes) {
  final upper = <MuscleGroup>[
    MuscleGroup.chest,
    MuscleGroup.back,
    MuscleGroup.shoulders,
    MuscleGroup.arms,
  ].fold<double>(0, (sum, group) => sum + (volumes[group] ?? 0));
  final lower = volumes[MuscleGroup.legs] ?? 0;
  final total = upper + lower;
  if (total <= 0) return BodyBalance.balanced;
  final upperShare = upper / total;
  // 하체는 한 부위뿐이라 40%만 넘어도 균형으로 본다.
  if (upperShare >= 0.75) return BodyBalance.upper;
  if (upperShare <= 0.4) return BodyBalance.lower;
  return BodyBalance.balanced;
}

/// 다음 진화까지 남은 레벨을 사람이 읽는 문구로 만든다.
String evolutionHint(CharacterGrowth growth) => growth.isMaxStage
    ? '최고 단계에 도달했습니다'
    : '다음 진화까지 레벨 ${growth.levelsUntilNextEvolution}';
