import 'package:flutter/material.dart';

import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../domain/entities/character_attribute.dart';
import '../../../../domain/entities/character_identity.dart';
import '../../../../domain/entities/discipline.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/usecases/calculate_character_growth.dart';

const List<String> _stagePrefixes = <String>['새싹', '튼튼', '근육', '타이탄'];

/// 진화 단계 수. 이름 목록이 아니라 이 값으로 범위를 잡는다.
const int kStageCount = 5;

/// 종족에 맞는 단계 이름. 강아지에게 "냥"을 붙이던 자리다.
String stageName(CharacterSpecies species, int stage) {
  final suffix = switch (species) {
    CharacterSpecies.cat => '냥',
    CharacterSpecies.dog => '멍',
    CharacterSpecies.bear => '곰',
  };
  final safe = stage.clamp(0, kStageCount - 1);
  return safe == _stagePrefixes.length
      ? '$suffix관왕'
      : '${_stagePrefixes[safe]} $suffix';
}

/// 주 종목 복장을 입은 모습을 먼저 그리고, 그 그림이 아직 없으면 기본 모습으로
/// 떨어진다. 종목 아트를 하나씩 채워 넣어도 화면이 비지 않는다.
class CharacterSprite extends StatelessWidget {
  const CharacterSprite({
    required this.species,
    required this.stage,
    this.discipline,
    this.size = 168,
    super.key,
  });

  /// 성장 상태를 그대로 가진 화면에서 쓰는 지름길.
  CharacterSprite.of({
    required CharacterIdentity identity,
    required CharacterGrowth growth,
    double size = 168,
    Key? key,
  }) : this(
         species: identity.species,
         stage: growth.evolutionStage,
         discipline: growth.primaryDiscipline,
         size: size,
         key: key,
       );

  final CharacterSpecies species;
  final int stage;

  /// 주 종목. 없으면 기본 모습을 그린다.
  final Discipline? discipline;
  final double size;

  @override
  Widget build(BuildContext context) {
    final safeStage = stage.clamp(0, kStageCount - 1);
    final base = stageAsset(species, safeStage);
    final outfit = discipline == null
        ? null
        : outfitAsset(speciesKey(species), discipline!, safeStage);
    final fallback = Image.asset(
      base,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => Icon(
        Icons.pets_rounded,
        size: size * 0.55,
        color: context.tokens.brand,
      ),
    );
    if (outfit == null) return fallback;
    return Image.asset(
      outfit,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

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
          CharacterSprite.of(identity: identity, growth: growth, size: 160),
          const SizedBox(height: AppSpacing.md),
          Text(identity.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${stageName(identity.species, growth.evolutionStage)} · '
            '${traitCopy(identity.trait).name}',
            style: TextStyle(fontSize: 12.5, color: t.faintText),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 요즘 가장 많이 한 종목에서 온 칭호.
          Text(
            'Lv. ${growth.totalLevel} · ${growth.title}',
            style: TextStyle(
              color: t.mutedText,
              fontWeight: FontWeight.w600,
              fontFeatures: kTabularFigures,
            ),
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
  const MuscleGrowthBar({required this.growth, super.key});

  final AttributeGrowth growth;

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
                  attributeLabel(growth.attribute),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Lv. ${growth.level}',
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
              value: growth.progress,
              minHeight: 8,
              color: t.brand,
              backgroundColor: t.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            growth.xpForNextLevel == 0
                ? '최고 레벨'
                : '${growth.xpIntoLevel} / ${growth.xpForNextLevel} XP',
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
