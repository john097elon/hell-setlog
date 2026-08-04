import 'dart:math' as math;

import '../entities/character_attribute.dart';
import '../entities/character_identity.dart';
import '../entities/discipline.dart';

/// 레벨 n에서 n+1로 가는 데 필요한 XP. 레벨이 오를수록 완만하게 늘어난다.
const int _baseXpPerLevel = 40;

/// 진화 단계에 필요한 합산 레벨. 능력치 4종이 각각 1에서 시작하므로 4가 바닥이다.
const List<int> evolutionThresholds = <int>[0, 10, 24, 48, 96];

/// 한 능력치의 성장 상태.
class AttributeGrowth {
  const AttributeGrowth({
    required this.attribute,
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  final CharacterAttribute attribute;
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
    required this.attributes,
    required this.totalXp,
    required this.totalLevel,
    required this.evolutionStage,
    required this.weeklyXp,
    this.primaryDiscipline,
    this.nextEvolutionThreshold,
  });

  final List<AttributeGrowth> attributes;
  final int totalXp;
  final int totalLevel;

  /// 0부터 시작하는 진화 단계 인덱스.
  final int evolutionStage;

  /// 최근 7일 동안 얻은 XP. 지금 성장 중인지 보여준다.
  final int weeklyXp;

  /// 가장 많이 한 종목. 칭호와 복장을 여기서 정한다. 기록이 없으면 null.
  final Discipline? primaryDiscipline;
  final int? nextEvolutionThreshold;

  bool get isMaxStage => nextEvolutionThreshold == null;

  /// 주 종목에 붙는 칭호.
  String get title => titleForDiscipline(primaryDiscipline);

  /// 주 종목 복장 스프라이트 경로. 종족을 알아야 해서 화면에서 만든다.
  String? outfitFor(String speciesKey) => primaryDiscipline == null
      ? null
      : outfitAsset(speciesKey, primaryDiscipline!, evolutionStage);

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

  Map<CharacterAttribute, int> get levels => <CharacterAttribute, int>{
    for (final growth in attributes) growth.attribute: growth.level,
  };
}

/// 종목별로 쌓인 점수에서 캐릭터 성장을 계산한다.
///
/// [effortByDiscipline]은 전체 기간 누적, [weeklyEffort]는 최근 7일,
/// [recentEffort]는 칭호를 정할 최근 구간(기본은 최근 30일)이다.
/// [recentEffort]가 비어 있으면 전체 누적으로 칭호를 정한다.
CharacterGrowth calculateCharacterGrowth(
  Map<Discipline, double> effortByDiscipline, {
  Map<Discipline, double> weeklyEffort = const <Discipline, double>{},
  Map<Discipline, double> recentEffort = const <Discipline, double>{},
  Discipline? preferredDiscipline,
}) {
  final byAttribute = <CharacterAttribute, double>{};
  for (final entry in effortByDiscipline.entries) {
    if (entry.value <= 0) continue;
    final weights = disciplineAttributes[entry.key];
    if (weights == null) continue;
    for (final weight in weights.entries) {
      byAttribute.update(
        weight.key,
        (value) => value + entry.value * weight.value,
        ifAbsent: () => entry.value * weight.value,
      );
    }
  }
  final attributes = <AttributeGrowth>[
    for (final attribute in CharacterAttribute.values)
      _growthFor(attribute, byAttribute[attribute] ?? 0),
  ];
  final totalXp = attributes.fold(0, (sum, growth) => sum + growth.xp);
  final totalLevel = attributes.fold(0, (sum, growth) => sum + growth.level);
  final stage = evolutionStageForLevel(totalLevel);
  return CharacterGrowth(
    attributes: attributes,
    totalXp: totalXp,
    totalLevel: totalLevel,
    evolutionStage: stage,
    weeklyXp: _round(weeklyEffort.values.fold(0, (sum, value) => sum + value)),
    // 사용자가 직접 고른 종목이 있으면 기록보다 그 선택을 따른다.
    primaryDiscipline:
        preferredDiscipline ??
        primaryDisciplineOf(
          recentEffort.isEmpty ? effortByDiscipline : recentEffort,
        ),
    nextEvolutionThreshold: stage == evolutionThresholds.length - 1
        ? null
        : evolutionThresholds[stage + 1],
  );
}

/// 가장 많이 한 종목. 동점이면 앞선 종목을 고른다. 기록이 없으면 null.
Discipline? primaryDisciplineOf(Map<Discipline, double> effort) {
  Discipline? best;
  var bestValue = 0.0;
  for (final entry in effort.entries) {
    if (entry.value > bestValue) {
      best = entry.key;
      bestValue = entry.value;
    }
  }
  return best;
}

/// 레벨 [level]에서 다음 레벨까지 필요한 XP.
int xpToReachNextLevel(int level) => _baseXpPerLevel * level;

/// 합산 레벨에 해당하는 진화 단계.
int evolutionStageForLevel(int totalLevel) => math.max(
  0,
  evolutionThresholds.lastIndexWhere((threshold) => totalLevel >= threshold),
);

AttributeGrowth _growthFor(CharacterAttribute attribute, double points) {
  final xp = _round(points);
  var remaining = xp;
  var level = 1;
  // 레벨 1→2는 40XP, 2→3은 80XP처럼 필요량이 늘어난다.
  while (level < 99 && remaining >= xpToReachNextLevel(level)) {
    remaining -= xpToReachNextLevel(level);
    level++;
  }
  return AttributeGrowth(
    attribute: attribute,
    xp: xp,
    level: level,
    xpIntoLevel: remaining,
    xpForNextLevel: level >= 99 ? 0 : xpToReachNextLevel(level),
  );
}

int _round(double points) => points <= 0 ? 0 : points.floor();

/// 다음 진화까지 남은 레벨을 사람이 읽는 문구로 만든다.
String evolutionHint(CharacterGrowth growth) => growth.isMaxStage
    ? '최고 단계에 도달했습니다'
    : '다음 진화까지 레벨 ${growth.levelsUntilNextEvolution}';

/// 성향 보너스가 붙는 구간의 배수.
const double traitBonusMultiplier = 1.25;

/// 성향에 맞는 기록이면 경험치를 더 준다.
///
/// 웨이트는 반복 수로 가른다. 파워형은 6회 이하, 지구력형은 12회 이상,
/// 균형형은 그 사이다. 세 성향이 서로 다른 구간을 가져가 어떤 선택도 손해가 아니다.
/// 웨이트가 아닌 종목은 성향이 겨냥하는 성격에 맞을 때 보너스를 준다.
double traitMultiplier(
  CharacterTrait trait,
  int reps, {
  Discipline discipline = Discipline.strength,
}) {
  if (trackingModeOf(discipline) == TrackingMode.setsReps) {
    final matches = switch (trait) {
      CharacterTrait.power => reps > 0 && reps <= 6,
      CharacterTrait.endurance => reps >= 12,
      CharacterTrait.balanced => reps >= 7 && reps <= 11,
    };
    return matches ? traitBonusMultiplier : 1;
  }
  final matches = switch (trait) {
    // 짧고 강한 운동은 파워형, 오래 가는 운동은 지구력형이 가져간다.
    CharacterTrait.power => discipline == Discipline.striking,
    CharacterTrait.endurance =>
      discipline == Discipline.running ||
          discipline == Discipline.swimming ||
          discipline == Discipline.cycling,
    CharacterTrait.balanced =>
      discipline == Discipline.grappling || discipline == Discipline.mobility,
  };
  return matches ? traitBonusMultiplier : 1;
}

/// 성향 설명. 선택 화면과 캐릭터 화면이 같은 문구를 쓴다.
({String name, String detail}) traitCopy(CharacterTrait trait) =>
    switch (trait) {
      CharacterTrait.power => (
        name: '파워형',
        detail: '6회 이하 고중량 세트와 입식 격투에서 경험치를 더 받아요',
      ),
      CharacterTrait.endurance => (
        name: '지구력형',
        detail: '12회 이상 고반복 세트와 달리기·수영·사이클에서 경험치를 더 받아요',
      ),
      CharacterTrait.balanced => (
        name: '균형형',
        detail: '7~11회 중간 반복 세트와 그래플링·유연성 운동에서 경험치를 더 받아요',
      ),
    };

/// 종족 이름과 한 줄 소개.
({String name, String detail}) speciesCopy(CharacterSpecies species) =>
    switch (species) {
      CharacterSpecies.cat => (name: '냥이', detail: '민첩하고 꾸준한 타입'),
      CharacterSpecies.dog => (name: '멍이', detail: '활발하고 성실한 타입'),
      CharacterSpecies.bear => (name: '곰이', detail: '묵직하고 강한 타입'),
    };
