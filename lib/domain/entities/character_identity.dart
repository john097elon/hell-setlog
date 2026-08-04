import 'discipline.dart';

/// 사용자가 고른 스타터 종족. 아트 라인이 종족마다 다르다.
enum CharacterSpecies { cat, dog, bear }

/// 성향. 어떤 운동에서 경험치를 더 받을지 정한다.
enum CharacterTrait { power, endurance, balanced }

/// 사용자가 만든 캐릭터의 정체성. 성장 수치와 별개로 저장된다.
class CharacterIdentity {
  const CharacterIdentity({
    required this.species,
    required this.trait,
    required this.name,
    this.preferredDiscipline,
  });

  final CharacterSpecies species;
  final CharacterTrait trait;
  final String name;

  /// 사용자가 직접 고른 주 종목. 비워 두면 최근 기록에서 자동으로 정한다.
  final Discipline? preferredDiscipline;

  CharacterIdentity copyWith({
    CharacterSpecies? species,
    CharacterTrait? trait,
    String? name,
    Discipline? preferredDiscipline,
    bool clearPreferredDiscipline = false,
  }) => CharacterIdentity(
    species: species ?? this.species,
    trait: trait ?? this.trait,
    name: name ?? this.name,
    preferredDiscipline: clearPreferredDiscipline
        ? null
        : (preferredDiscipline ?? this.preferredDiscipline),
  );
}

/// 저장된 문자열을 종족으로 되돌린다. 모르는 값이면 기본 종족.
CharacterSpecies speciesFrom(String? raw) => switch (raw) {
  'dog' => CharacterSpecies.dog,
  'bear' => CharacterSpecies.bear,
  _ => CharacterSpecies.cat,
};

/// 저장된 문자열을 성향으로 되돌린다. 모르는 값이면 균형형.
CharacterTrait traitFrom(String? raw) => switch (raw) {
  'power' => CharacterTrait.power,
  'endurance' => CharacterTrait.endurance,
  _ => CharacterTrait.balanced,
};

String speciesKey(CharacterSpecies species) => species.name;

String traitKey(CharacterTrait trait) => trait.name;
