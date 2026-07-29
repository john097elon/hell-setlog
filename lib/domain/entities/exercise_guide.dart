/// 운동 종목의 안내 정보.
class ExerciseGuide {
  const ExerciseGuide({
    required this.id,
    required this.nameKo,
    required this.summary,
    required this.steps,
    required this.tips,
    required this.mistakes,
    required this.primaryMuscles,
    required this.beginnerFriendly,
  });

  factory ExerciseGuide.fromJson(Map<String, Object?> json) => ExerciseGuide(
    id: json['id'] as String,
    nameKo: json['nameKo'] as String,
    summary: json['summary'] as String,
    steps: _strings(json['steps']),
    tips: _strings(json['tips']),
    mistakes: _strings(json['mistakes']),
    primaryMuscles: _strings(json['primaryMuscles']),
    beginnerFriendly: json['beginnerFriendly'] as bool,
  );

  final String id;
  final String nameKo;
  final String summary;
  final List<String> steps;
  final List<String> tips;
  final List<String> mistakes;
  final List<String> primaryMuscles;
  final bool beginnerFriendly;
}

List<String> _strings(Object? value) => (value as List<Object?>)
    .map((item) => item as String)
    .toList(growable: false);
