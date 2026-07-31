import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../application/character_providers.dart';
import 'widgets/growth_view.dart';

/// 기록한 운동에서 자란 캐릭터를 보여준다.
class MonsterPage extends ConsumerWidget {
  const MonsterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growth = ref.watch(characterGrowthProvider);
    return Scaffold(
      backgroundColor: context.tokens.bg,
      body: growth.when(
        loading: () => const AppLoading(),
        error: (_, _) => const AppEmptyState(
          icon: Icons.pets_rounded,
          title: '캐릭터 정보를 불러오지 못했습니다',
        ),
        data: (value) => value.totalXp == 0
            ? const _EmptyCharacter()
            : _GrowthContent(growth: value),
      ),
    );
  }
}

class _GrowthContent extends ConsumerWidget {
  const _GrowthContent({required this.growth});

  final CharacterGrowth growth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final seenLevel = ref.watch(seenCharacterLevelProvider).valueOrNull;
    // 지난번에 본 레벨보다 올랐으면 한 번만 축하한다.
    final gained = seenLevel == null ? 0 : growth.totalLevel - seenLevel;
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(characterVolumesProvider)
          ..invalidate(characterWeeklyVolumesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          if (gained > 0)
            LevelUpBanner(
              gainedLevels: gained,
              onDismiss: () => markCharacterLevelSeen(ref, growth.totalLevel),
            ),
          CharacterHero(growth: growth),
          const SizedBox(height: AppSpacing.lg),
          WeeklyGrowthStrip(growth: growth),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '부위별 성장',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: t.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final muscle in growth.muscles) MuscleGrowthBar(muscle: muscle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '완료한 세트의 볼륨 100kg마다 1XP를 얻어요. 준비 세트는 빠집니다.',
            style: TextStyle(fontSize: 12.5, color: t.faintText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyCharacter extends StatelessWidget {
  const _EmptyCharacter();

  @override
  Widget build(BuildContext context) => const AppEmptyState(
    icon: Icons.pets_rounded,
    title: '운동을 기록하면 캐릭터가 자랍니다',
    message: '세트를 완료할 때마다 부위별 경험치가 쌓여요.',
  );
}
