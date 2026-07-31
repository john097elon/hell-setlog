import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../../../domain/entities/character_identity.dart';
import 'character_setup_page.dart';
import '../application/character_identity_controller.dart';
import '../application/character_providers.dart';
import 'evolution_page.dart';
import 'widgets/growth_view.dart';

/// 기록한 운동에서 자란 캐릭터를 보여준다.
class MonsterPage extends ConsumerWidget {
  const MonsterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(characterIdentityProvider);
    return Scaffold(
      backgroundColor: context.tokens.bg,
      body: identity.when(
        loading: () => const AppLoading(),
        error: (_, _) => const AppEmptyState(
          icon: Icons.pets_rounded,
          title: '캐릭터 정보를 불러오지 못했습니다',
        ),
        // 아직 캐릭터를 안 골랐으면 만들기부터 안내한다.
        data: (value) =>
            value == null ? const _NeedsSetup() : _Growth(identity: value),
      ),
    );
  }
}

/// 캐릭터를 아직 만들지 않은 상태.
class _NeedsSetup extends ConsumerWidget {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppEmptyState(
    icon: Icons.pets_rounded,
    title: '함께 운동할 캐릭터를 만들어요',
    message: '종족과 성향을 고르고 이름을 지어 주세요.',
    action: FilledButton(
      onPressed: () => openCharacterSetup(context),
      child: const Text('캐릭터 만들기'),
    ),
  );
}

/// 캐릭터 만들기/바꾸기 화면을 연다.
Future<void> openCharacterSetup(
  BuildContext context, {
  CharacterIdentity? initial,
}) => Navigator.of(context)
    .push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CharacterSetupPage(initial: initial),
      ),
    )
    .then((_) {});

class _Growth extends ConsumerWidget {
  const _Growth({required this.identity});

  final CharacterIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(characterGrowthProvider)
      .when(
        loading: () => const AppLoading(),
        error: (_, _) => const AppEmptyState(
          icon: Icons.pets_rounded,
          title: '캐릭터 정보를 불러오지 못했습니다',
        ),
        data: (value) => _GrowthContent(growth: value, identity: identity),
      );
}

class _GrowthContent extends ConsumerStatefulWidget {
  const _GrowthContent({required this.growth, required this.identity});

  final CharacterGrowth growth;
  final CharacterIdentity identity;

  @override
  ConsumerState<_GrowthContent> createState() => _GrowthContentState();
}

class _GrowthContentState extends ConsumerState<_GrowthContent> {
  bool _evolutionScheduled = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final seenLevel = ref.watch(seenCharacterLevelProvider).valueOrNull;
    final seenStage = ref.watch(seenCharacterEvolutionStageProvider);
    final hasPendingEvolution = seenStage.when(
      data: (stage) => widget.growth.evolutionStage > (stage ?? 0),
      loading: () => false,
      error: (_, _) => false,
    );
    final evolutionStatusLoaded = seenStage.when(
      data: (_) => true,
      loading: () => false,
      error: (_, _) => false,
    );
    if (hasPendingEvolution && !_evolutionScheduled) {
      _evolutionScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showPendingCharacterEvolution(
          context,
          ref,
          identity: widget.identity,
          growth: widget.growth,
        );
        if (mounted) setState(() => _evolutionScheduled = false);
      });
    }
    // 지난번에 본 레벨보다 올랐으면 한 번만 축하한다.
    final gained = seenLevel == null ? 0 : widget.growth.totalLevel - seenLevel;
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(characterVolumesProvider)
          ..invalidate(characterWeeklyVolumesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          if (evolutionStatusLoaded && !hasPendingEvolution && gained > 0)
            LevelUpBanner(
              gainedLevels: gained,
              onDismiss: () =>
                  markCharacterLevelSeen(ref, widget.growth.totalLevel),
            ),
          CharacterHero(growth: widget.growth, identity: widget.identity),
          const SizedBox(height: AppSpacing.lg),
          WeeklyGrowthStrip(growth: widget.growth),
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
          for (final muscle in widget.growth.muscles)
            MuscleGrowthBar(muscle: muscle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '완료한 세트의 볼륨 100kg마다 1XP를 얻어요. 준비 세트는 빠집니다.\n'
            '${traitCopy(widget.identity.trait).detail}.',
            style: TextStyle(fontSize: 12.5, color: t.faintText, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () =>
                openCharacterSetup(context, initial: widget.identity),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('캐릭터 바꾸기'),
          ),
        ],
      ),
    );
  }
}
