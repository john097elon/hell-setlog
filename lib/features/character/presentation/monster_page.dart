import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/core/widgets/app_states.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/usecases/calculate_character_growth.dart';
import 'package:heal_setlog/features/character/application/character_providers.dart';
import 'package:heal_setlog/features/character/presentation/models/monster_view_data.dart';
import 'package:heal_setlog/features/character/presentation/widgets/monster_stat_grid.dart';

const _muscleGroups = <MuscleGroup>[
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.shoulders,
  MuscleGroup.legs,
  MuscleGroup.arms,
  MuscleGroup.core,
];
const _muscleLabels = <MuscleGroup, String>{
  MuscleGroup.chest: '가슴',
  MuscleGroup.back: '등',
  MuscleGroup.shoulders: '어깨',
  MuscleGroup.legs: '하체',
  MuscleGroup.arms: '팔',
  MuscleGroup.core: '코어',
};
const _stageNames = <String>['새싹 냥', '튼튼 냥', '근육 냥', '타이탄 냥', '냥관왕'];
const _stageAssets = <String>[
  'assets/character/stage1_nyaongi.png',
  'assets/character/stage2_geunnyangi.png',
  'assets/character/stage3_musclecat.png',
  'assets/character/stage4_titannyang.png',
  'assets/character/stage5_nyagwanwang.png',
];

/// Displays character evolution derived from locally recorded workouts.
class MonsterPage extends StatelessWidget {
  const MonsterPage({this.data = monsterMockViewData, super.key});

  final MonsterViewData data;

  @override
  Widget build(BuildContext context) {
    try {
      ProviderScope.containerOf(context, listen: false);
      return Consumer(
        builder: (context, ref, _) {
          final volumes = ref.watch(characterVolumesProvider);
          return Scaffold(
            body: volumes.when(
              data: (data) => data.values.every((volume) => volume == 0)
                  ? const _EmptyCharacter()
                  : _GrowthContent(growth: calculateCharacterGrowth(data)),
              loading: () => const AppLoading(),
              error: (_, _) => const _CharacterError(),
            ),
          );
        },
      );
    } on StateError {
      return _LegacyMonster(data: data);
    }
  }
}

class _LegacyMonster extends StatelessWidget {
  const _LegacyMonster({required this.data});

  final MonsterViewData data;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Text(copy.monsterMockName, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${copy.level} ${data.level} · ${_bodyTypeLabel(context, data.bodyType)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.tokens.mutedText,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Image.asset(
                data.stageAssetPath,
                width: 192,
                height: 192,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(copy.monsterExperience, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: LinearProgressIndicator(
                value: data.experienceProgress,
                minHeight: 10,
                color: context.tokens.brand,
                backgroundColor: context.tokens.surface,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${formatInt(data.experience)} / ${formatInt(data.experienceMaximum)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: kTabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        MonsterStatGrid(
          stats: data.stats,
          labelFor: (kind) => switch (kind) {
            MonsterStatKind.arm => copy.monsterStatArm,
            MonsterStatKind.leg => copy.monsterStatLeg,
            MonsterStatKind.core => copy.monsterStatCore,
            MonsterStatKind.endure => copy.monsterStatEndure,
          },
        ),
      ],
    );
  }

  String _bodyTypeLabel(BuildContext context, MonsterBodyType bodyType) =>
      switch (bodyType) {
        MonsterBodyType.upper => context.l10n.monsterBodyTypeUpper,
        MonsterBodyType.lower => context.l10n.monsterBodyTypeLower,
        MonsterBodyType.balanced => context.l10n.monsterBodyTypeBalanced,
      };
}

class _GrowthContent extends StatelessWidget {
  const _GrowthContent({required this.growth});

  final CharacterGrowth growth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Text('캐릭터 성장', style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: <Widget>[
                Image.asset(
                  _stageAssets[growth.evolutionStage],
                  width: 192,
                  height: 192,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.fitness_center_rounded,
                    size: 96,
                    color: context.tokens.brand,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _stageNames[growth.evolutionStage],
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '합산 레벨 ${growth.totalLevel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('부위별 레벨', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        ..._muscleGroups.map(
          (muscleGroup) => _MuscleLevelBar(
            label: _muscleLabels[muscleGroup]!,
            level: growth.levels[muscleGroup]!,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          growth.nextEvolutionThreshold == null
              ? '최고 단계에 도달했습니다'
              : '다음 진화까지 레벨 ${growth.levelsUntilNextEvolution}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.tokens.mutedText,
            fontFeatures: kTabularFigures,
          ),
        ),
      ],
    );
  }
}

class _MuscleLevelBar extends StatelessWidget {
  const _MuscleLevelBar({required this.label, required this.level});

  final String label;
  final int level;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              'Lv. $level',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontFeatures: kTabularFigures),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: level / 99,
          minHeight: AppSpacing.sm,
          color: context.tokens.brand,
          backgroundColor: context.tokens.surface,
        ),
      ],
    ),
  );
}

class _EmptyCharacter extends StatelessWidget {
  const _EmptyCharacter();

  @override
  Widget build(BuildContext context) => const AppEmptyState(
    icon: Icons.fitness_center_rounded,
    title: '운동을 기록하면 캐릭터가 성장합니다',
  );
}

class _CharacterError extends StatelessWidget {
  const _CharacterError();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('캐릭터 성장 정보를 불러오지 못했습니다'));
}
