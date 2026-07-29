import 'package:flutter/material.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';

/// 운동 종목 썸네일. thumbnailUrl이 있으면 이미지를, 없으면 장비 글리프 플레이스홀더.
///
/// 실제 일러스트(ComfyUI/agy 생성)는 thumbnailUrl로 채워지면 자동 표시된다.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({
    required this.equipment,
    this.thumbnailUrl,
    this.size = 56,
    super.key,
  });

  final Equipment equipment;
  final String? thumbnailUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = size * 0.26;
    final url = thumbnailUrl;
    final hasImage = url != null && url.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // 이미지 있으면 순백 배경(일러스트가 흰 배경이라 이음새 없음), 없으면 은은한 회색.
        color: hasImage ? Colors.white : t.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? Padding(padding: EdgeInsets.all(size * 0.04), child: _image(url, t))
          : _glyph(t),
    );
  }

  Widget _image(String url, AppTokens t) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _glyph(t),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _glyph(t),
    );
  }

  Widget _glyph(AppTokens t) =>
      Icon(_equipmentIcon(equipment), size: size * 0.42, color: t.faintText);
}

IconData _equipmentIcon(Equipment equipment) => switch (equipment) {
  Equipment.barbell => Icons.fitness_center,
  Equipment.dumbbell => Icons.fitness_center,
  Equipment.machine => Icons.settings_input_component_outlined,
  Equipment.cable => Icons.cable_outlined,
  Equipment.bodyweight => Icons.accessibility_new_rounded,
  Equipment.kettlebell => Icons.sports_gymnastics_outlined,
  Equipment.band => Icons.waves_outlined,
  Equipment.other => Icons.fitness_center,
};

/// 장비 한국어 라벨.
String equipmentLabelKo(Equipment equipment) => switch (equipment) {
  Equipment.barbell => '바벨',
  Equipment.dumbbell => '덤벨',
  Equipment.machine => '머신',
  Equipment.cable => '케이블',
  Equipment.bodyweight => '맨몸',
  Equipment.kettlebell => '케틀벨',
  Equipment.band => '밴드',
  Equipment.other => '기타',
};
