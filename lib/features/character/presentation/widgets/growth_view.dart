import 'package:flutter/material.dart';

import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../domain/entities/character_identity.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/usecases/calculate_character_growth.dart';

const List<String> kStageNames = <String>[
  '새싹 냥',
  '튼튼 냥',
  '근육 냥',
  '타이탄 냥',
  '냥관왕',
];

/// 종족과 단계로 스프라이트 경로를 만든다.
String stageAsset(CharacterSpecies species, int stage) =>
    'assets/character/${speciesKey(species)}_stage${stage + 1}.png';
const Map<MuscleGroup, String> kMuscleLabels = <MuscleGroup, String>{
  MuscleGroup.chest: '가슴',
  MuscleGroup.back: '등',
  MuscleGroup.shoulders: '어깨',
  MuscleGroup.legs: '하체',
  MuscleGroup.arms: '팔',
  MuscleGroup.core: '코어',
};

String balanceLabel(BodyBalance balance) => switch (balance) {
  BodyBalance.upper => '상체 중심',
  BodyBalance.lower => '하체 중심',
  BodyBalance.balanced => '균형 잡힘',
};

/// 캐릭터 카드. 단계 아트, 이름, 다음 진화까지의 진행률.
class CharacterHero extends StatelessWidget {
  const CharacterHero({
    required this.growth,
    required this.identity,
    super.key,
  });

  final CharacterGrowth growth;
  final CharacterIdentity identity;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: <Widget>[
          Image.asset(
            stageAsset(identity.species, growth.evolutionStage),
            width: 160,
            height: 160,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) =>
                Icon(Icons.pets_rounded, size: 96, color: t.brand),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(identity.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${kStageNames[growth.evolutionStage]} · ${traitCopy(identity.trait).name}',
            style: TextStyle(fontSize: 12.5, color: t.faintText),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            balanceLabel(growth.balance),
            style: TextStyle(color: t.mutedText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: growth.evolutionProgress,
              minHeight: 10,
              color: t.brand,
              backgroundColor: t.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            evolutionHint(growth),
            style: TextStyle(
              fontSize: 12.5,
              color: t.faintText,
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// 이번 주 성장 요약.
class WeeklyGrowthStrip extends StatelessWidget {
  const WeeklyGrowthStrip({required this.growth, super.key});

  final CharacterGrowth growth;

  @override
  Widget build(BuildContext context) {
    return AppMetricRow(
      metrics: <AppMetric>[
        AppMetric(label: '레벨', value: '${growth.totalLevel}', size: 22),
        AppMetric(
          label: '이번 주',
          value: '+${formatCompactNumber(growth.weeklyXp)} XP',
          size: 22,
        ),
        AppMetric(
          label: '총 경험치',
          value: '${formatCompactNumber(growth.totalXp)} XP',
          size: 22,
        ),
      ],
    );
  }
}

/// 부위별 레벨과 다음 레벨까지의 진행률.
class MuscleGrowthBar extends StatelessWidget {
  const MuscleGrowthBar({required this.muscle, super.key});

  final MuscleGrowth muscle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  kMuscleLabels[muscle.group] ?? '기타',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Lv. ${muscle.level}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: muscle.progress,
              minHeight: 8,
              color: t.brand,
              backgroundColor: t.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            muscle.xpForNextLevel == 0
                ? '최고 레벨'
                : '${muscle.xpIntoLevel} / ${muscle.xpForNextLevel} XP',
            style: TextStyle(
              fontSize: 11.5,
              color: t.faintText,
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// 레벨이 오른 뒤 처음 들어왔을 때 보여 주는 배너.
class LevelUpBanner extends StatelessWidget {
  const LevelUpBanner({
    required this.gainedLevels,
    required this.onDismiss,
    super.key,
  });

  final int gainedLevels;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: t.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.brand.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, color: t.brand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '레벨이 $gainedLevels 올랐어요',
              style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
            ),
          ),
          IconButton(
            tooltip: '닫기',
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 18, color: t.mutedText),
          ),
        ],
      ),
    );
  }
}
