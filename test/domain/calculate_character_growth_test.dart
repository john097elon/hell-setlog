import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/domain/entities/character_attribute.dart';
import 'package:heal_setlog/domain/entities/character_identity.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';

void main() {
  test('기록이 없으면 모든 능력치가 레벨 1이고 칭호는 새내기다', () {
    final growth = calculateCharacterGrowth(const <Discipline, double>{});

    expect(growth.totalXp, 0);
    expect(growth.totalLevel, 1);
    expect(growth.evolutionStage, 0);
    expect(growth.attributes.every((item) => item.level == 1), isTrue);
    expect(growth.primaryDiscipline, isNull);
    expect(growth.title, '새내기');
  });

  test('웨이트는 근력을, 러닝은 지구력을 올린다', () {
    final lifter = calculateCharacterGrowth(<Discipline, double>{
      Discipline.strength: 200,
    });
    final runner = calculateCharacterGrowth(<Discipline, double>{
      Discipline.running: 200,
    });

    int levelOf(CharacterGrowth growth, CharacterAttribute attribute) =>
        growth.levels[attribute]!;

    expect(
      levelOf(lifter, CharacterAttribute.strength),
      greaterThan(levelOf(lifter, CharacterAttribute.endurance)),
    );
    expect(
      levelOf(runner, CharacterAttribute.endurance),
      greaterThan(levelOf(runner, CharacterAttribute.strength)),
    );
  });

  test('그래플링은 기술과 근력·지구력을 함께 올린다', () {
    final growth = calculateCharacterGrowth(<Discipline, double>{
      Discipline.grappling: 300,
    });

    expect(growth.levels[CharacterAttribute.technique]! > 1, isTrue);
    expect(growth.levels[CharacterAttribute.strength]! > 1, isTrue);
    expect(growth.levels[CharacterAttribute.endurance]! > 1, isTrue);
    expect(growth.levels[CharacterAttribute.mobility], 1);
  });

  test('가장 많이 한 종목이 칭호가 된다', () {
    final growth = calculateCharacterGrowth(<Discipline, double>{
      Discipline.strength: 100,
      Discipline.grappling: 400,
      Discipline.running: 50,
    });

    expect(growth.primaryDiscipline, Discipline.grappling);
    expect(growth.title, '그래플러');
    // 복장 그림은 종족·종목·진화 단계마다 다르다.
    expect(
      growth.outfitFor('cat'),
      'assets/character/outfit/cat_grappling_stage'
      '${growth.evolutionStage + 1}.png',
    );
  });

  test('칭호는 최근 기록을 우선한다', () {
    // 예전에는 웨이트만 했지만 요즘은 달리기를 한다면 러너다.
    final growth = calculateCharacterGrowth(
      <Discipline, double>{Discipline.strength: 5000, Discipline.running: 100},
      recentEffort: <Discipline, double>{Discipline.running: 200},
    );

    expect(growth.primaryDiscipline, Discipline.running);
    expect(growth.title, '러너');
  });

  test('직접 고른 주 종목이 기록보다 우선한다', () {
    // 웨이트만 했어도 주 종목을 주짓수로 골랐으면 그래플러다.
    final growth = calculateCharacterGrowth(<Discipline, double>{
      Discipline.strength: 500,
    }, preferredDiscipline: Discipline.grappling);

    expect(growth.primaryDiscipline, Discipline.grappling);
    expect(growth.title, '그래플러');
  });

  test('주 종목을 안 고르면 기록을 따라간다', () {
    final growth = calculateCharacterGrowth(<Discipline, double>{
      Discipline.running: 300,
      Discipline.strength: 100,
    });

    expect(growth.primaryDiscipline, Discipline.running);
  });

  test('레벨이 오르면 진화 단계도 오른다', () {
    expect(evolutionStageForLevel(1), 0);
    expect(evolutionStageForLevel(7), 1);
    expect(evolutionStageForLevel(44), 2);
    expect(evolutionStageForLevel(45), 3);
    expect(evolutionStageForLevel(9999), evolutionThresholds.length - 1);
  });

  test('최고 단계에서는 다음 임계값이 없다', () {
    final growth = calculateCharacterGrowth(<Discipline, double>{
      for (final discipline in Discipline.values) discipline: 5000000,
    });

    expect(growth.isMaxStage, isTrue);
    expect(growth.evolutionProgress, 1);
    expect(evolutionHint(growth), '최고 단계에 도달했습니다');
  });

  test('레벨 중간 진행률이 남은 XP로 계산된다', () {
    // 근력 60XP면 레벨 2에 20XP를 쌓은 상태다(1→2에 40 필요).
    final growth = calculateCharacterGrowth(<Discipline, double>{
      Discipline.strength: 60,
    });
    final strength = growth.attributes.firstWhere(
      (item) => item.attribute == CharacterAttribute.strength,
    );

    expect(strength.xp, 60);
    expect(strength.level, 2);
    expect(strength.xpIntoLevel, 20);
    expect(strength.xpForNextLevel, 80);
    expect(strength.progress, closeTo(0.25, 0.001));
  });

  test('이번 주 XP는 최근 기록만 센다', () {
    final growth = calculateCharacterGrowth(
      <Discipline, double>{Discipline.running: 500},
      weeklyEffort: <Discipline, double>{Discipline.running: 30},
    );

    expect(growth.weeklyXp, 30);
  });

  test('웨이트 성향 보너스는 반복 구간으로 가른다', () {
    expect(traitMultiplier(CharacterTrait.power, 5), traitBonusMultiplier);
    expect(traitMultiplier(CharacterTrait.power, 9), 1);
    expect(traitMultiplier(CharacterTrait.balanced, 9), traitBonusMultiplier);
    expect(traitMultiplier(CharacterTrait.endurance, 15), traitBonusMultiplier);
  });

  test('웨이트가 아닌 종목도 성향 보너스를 받는다', () {
    expect(
      traitMultiplier(
        CharacterTrait.endurance,
        0,
        discipline: Discipline.running,
      ),
      traitBonusMultiplier,
    );
    expect(
      traitMultiplier(CharacterTrait.power, 0, discipline: Discipline.striking),
      traitBonusMultiplier,
    );
    expect(
      traitMultiplier(
        CharacterTrait.balanced,
        0,
        discipline: Discipline.grappling,
      ),
      traitBonusMultiplier,
    );
    // 맞지 않는 조합은 보너스가 없다.
    expect(
      traitMultiplier(CharacterTrait.power, 0, discipline: Discipline.running),
      1,
    );
  });
}
