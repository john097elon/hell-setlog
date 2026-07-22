/// 근육군 필터 그룹의 기준.
enum MuscleGroup { chest, back, shoulders, legs, arms, core, fullBody, other }

/// 사용 장비.
enum Equipment { barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other }

/// 운동 종목. 로컬 DB가 원본이고 동기화는 추후 P3에서 추가한다.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.nameKo,
    required this.muscleGroup,
    required this.equipment,
    this.isCustom = false,
    this.thumbnailUrl,
  });

  final String id;
  final String name;
  final String nameKo;
  final MuscleGroup muscleGroup;
  final Equipment equipment;
  final bool isCustom;
  final String? thumbnailUrl;
}
