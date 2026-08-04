import 'discipline.dart';

/// 캐릭터 능력치. 부위별 근육 대신 이걸로 모든 종목을 담는다.
enum CharacterAttribute { strength, endurance, technique, mobility }

/// 종목이 어떤 능력치를 얼마나 올리는지.
///
/// 합이 1을 넘는 종목이 있다. 여러 능력을 동시에 쓰는 운동이라 그렇다.
/// 예를 들어 그래플링은 기술과 근력, 지구력을 함께 쓴다.
const Map<Discipline, Map<CharacterAttribute, double>> disciplineAttributes =
    <Discipline, Map<CharacterAttribute, double>>{
      Discipline.strength: <CharacterAttribute, double>{
        CharacterAttribute.strength: 1,
        CharacterAttribute.endurance: 0.2,
      },
      Discipline.running: <CharacterAttribute, double>{
        CharacterAttribute.endurance: 1,
        CharacterAttribute.strength: 0.1,
      },
      Discipline.swimming: <CharacterAttribute, double>{
        CharacterAttribute.endurance: 0.9,
        CharacterAttribute.mobility: 0.3,
      },
      Discipline.cycling: <CharacterAttribute, double>{
        CharacterAttribute.endurance: 1,
        CharacterAttribute.strength: 0.2,
      },
      Discipline.grappling: <CharacterAttribute, double>{
        CharacterAttribute.technique: 0.8,
        CharacterAttribute.strength: 0.4,
        CharacterAttribute.endurance: 0.4,
      },
      Discipline.striking: <CharacterAttribute, double>{
        CharacterAttribute.technique: 0.6,
        CharacterAttribute.endurance: 0.6,
        CharacterAttribute.strength: 0.2,
      },
      Discipline.mobility: <CharacterAttribute, double>{
        CharacterAttribute.mobility: 1,
        CharacterAttribute.technique: 0.2,
      },
      Discipline.other: <CharacterAttribute, double>{
        CharacterAttribute.endurance: 0.5,
        CharacterAttribute.strength: 0.3,
      },
    };

String attributeLabel(CharacterAttribute attribute) => switch (attribute) {
  CharacterAttribute.strength => '근력',
  CharacterAttribute.endurance => '지구력',
  CharacterAttribute.technique => '기술',
  CharacterAttribute.mobility => '유연성',
};

/// 주로 하는 종목에 붙는 칭호.
String titleForDiscipline(Discipline? discipline) => switch (discipline) {
  Discipline.strength => '리프터',
  Discipline.running => '러너',
  Discipline.swimming => '스위머',
  Discipline.cycling => '라이더',
  Discipline.grappling => '그래플러',
  Discipline.striking => '파이터',
  Discipline.mobility => '요기',
  Discipline.other => '운동인',
  null => '새내기',
};

/// 주 종목 복장을 입은 캐릭터 스프라이트 경로.
///
/// 종족·종목·단계마다 그림이 다르다. 아직 없는 조합은 호출 쪽에서 기본
/// 스프라이트로 떨어지므로 화면이 비지 않는다.
String outfitAsset(String speciesKey, Discipline discipline, int stage) =>
    'assets/character/outfit/${speciesKey}_${disciplineKey(discipline)}'
    '_stage${stage + 1}.png';
