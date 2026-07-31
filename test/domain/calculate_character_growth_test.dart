import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/character_identity.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';

void main() {
  test('볼륨 100kg마다 1XP를 준다', () {
    expect(xpForVolume(0), 0);
    expect(xpForVolume(-10), 0);
    expect(xpForVolume(99), 0);
    expect(xpForVolume(600), 6);
    expect(xpForVolume(12400), 124);
  });

  test('기록이 없으면 모든 부위가 레벨 1이고 진행률은 0이다', () {
    final growth = calculateCharacterGrowth(const <MuscleGroup, double>{});

    expect(growth.totalXp, 0);
    expect(growth.totalLevel, trackedMuscleGroups.length);
    expect(growth.evolutionStage, 0);
    expect(growth.muscles.every((muscle) => muscle.level == 1), isTrue);
    expect(growth.muscles.first.progress, 0);
  });

  test('레벨은 누적 XP를 단계별로 소진하며 오른다', () {
    // 40XP면 레벨 2, 추가 80XP면 레벨 3이 된다. 즉 12,000kg에서 레벨 3.
    final growth = calculateCharacterGrowth(<MuscleGroup, double>{
      MuscleGroup.chest: 12000,
    });
    final chest = growth.muscles.firstWhere(
      (muscle) => muscle.group == MuscleGroup.chest,
    );

    expect(chest.xp, 120);
    expect(chest.level, 3);
    expect(chest.xpIntoLevel, 0);
    expect(chest.xpForNextLevel, 120);
    expect(chest.progress, 0);
  });

  test('레벨 중간 진행률이 남은 XP로 계산된다', () {
    final growth = calculateCharacterGrowth(<MuscleGroup, double>{
      MuscleGroup.back: 6000,
    });
    final back = growth.muscles.firstWhere(
      (muscle) => muscle.group == MuscleGroup.back,
    );

    expect(back.xp, 60);
    expect(back.level, 2);
    expect(back.xpIntoLevel, 20);
    expect(back.xpForNextLevel, 80);
    expect(back.progress, closeTo(0.25, 0.001));
  });

  test('합산 레벨이 오르면 진화 단계도 오른다', () {
    final start = calculateCharacterGrowth(const <MuscleGroup, double>{});
    expect(start.evolutionStage, 0);
    expect(start.nextEvolutionThreshold, evolutionThresholds[1]);

    expect(evolutionStageForLevel(11), 0);
    expect(evolutionStageForLevel(12), 1);
    expect(evolutionStageForLevel(59), 2);
    expect(evolutionStageForLevel(60), 3);
    expect(evolutionStageForLevel(999), evolutionThresholds.length - 1);
  });

  test('최고 단계에서는 다음 임계값이 없다', () {
    final growth = calculateCharacterGrowth(<MuscleGroup, double>{
      for (final group in trackedMuscleGroups) group: 5000000,
    });

    expect(growth.isMaxStage, isTrue);
    expect(growth.evolutionProgress, 1);
    expect(evolutionHint(growth), '최고 단계에 도달했습니다');
  });

  test('상하체 비중으로 몸 균형을 판단한다', () {
    expect(
      calculateCharacterGrowth(<MuscleGroup, double>{
        MuscleGroup.chest: 9000,
        MuscleGroup.legs: 1000,
      }).balance,
      BodyBalance.upper,
    );
    expect(
      calculateCharacterGrowth(<MuscleGroup, double>{
        MuscleGroup.chest: 2000,
        MuscleGroup.legs: 8000,
      }).balance,
      BodyBalance.lower,
    );
    expect(
      calculateCharacterGrowth(<MuscleGroup, double>{
        MuscleGroup.chest: 5000,
        MuscleGroup.legs: 5000,
      }).balance,
      BodyBalance.balanced,
    );
  });

  test('성향은 서로 다른 반복 구간에서 보너스를 준다', () {
    // 세 성향이 겹치지 않는 구간을 가져가 어떤 선택도 손해가 아니다.
    expect(traitMultiplier(CharacterTrait.power, 5), traitBonusMultiplier);
    expect(traitMultiplier(CharacterTrait.power, 9), 1);
    expect(traitMultiplier(CharacterTrait.balanced, 9), traitBonusMultiplier);
    expect(traitMultiplier(CharacterTrait.balanced, 15), 1);
    expect(traitMultiplier(CharacterTrait.endurance, 15), traitBonusMultiplier);
    expect(traitMultiplier(CharacterTrait.endurance, 5), 1);
  });

  test('반복 수가 0이면 어떤 성향도 보너스를 주지 않는다', () {
    for (final trait in CharacterTrait.values) {
      expect(traitMultiplier(trait, 0), 1);
    }
  });

  test('이번 주 XP는 최근 볼륨만 센다', () {
    final growth = calculateCharacterGrowth(
      <MuscleGroup, double>{MuscleGroup.legs: 20000},
      weeklyVolumes: <MuscleGroup, double>{MuscleGroup.legs: 3000},
    );

    expect(growth.totalXp, 200);
    expect(growth.weeklyXp, 30);
  });
}
