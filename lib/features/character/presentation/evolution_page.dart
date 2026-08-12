import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/character_identity.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../application/character_identity_controller.dart';
import '../application/character_providers.dart';
import 'widgets/growth_view.dart';

/// 아직 보지 못한 진화가 있으면 연출을 띄우고 확인 상태를 저장한다.
Future<bool> showPendingCharacterEvolution(
  BuildContext context,
  WidgetRef ref, {
  CharacterIdentity? identity,
  CharacterGrowth? growth,
}) async {
  final resolvedIdentity =
      identity ?? await ref.read(characterIdentityProvider.future);
  if (resolvedIdentity == null || !context.mounted) return false;

  final resolvedGrowth =
      growth ?? await ref.read(characterGrowthProvider.future);
  if (resolvedGrowth == null) return false;
  final seenStage = await ref.read(seenCharacterEvolutionStageProvider.future);
  final previousStage = seenStage ?? 0;
  if (!context.mounted || resolvedGrowth.evolutionStage <= previousStage) {
    return false;
  }

  final route = Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => EvolutionPage(
        identity: resolvedIdentity,
        previousStage: previousStage < 0 ? 0 : previousStage,
        newStage: resolvedGrowth.evolutionStage,
      ),
    ),
  );
  await markCharacterEvolutionSeen(
    ref,
    stage: resolvedGrowth.evolutionStage,
    level: resolvedGrowth.totalLevel,
  );
  await route;
  return true;
}

/// 이전 스프라이트에서 새 진화 단계로 바뀌는 축하 화면.
class EvolutionPage extends StatelessWidget {
  const EvolutionPage({
    required this.identity,
    required this.previousStage,
    required this.newStage,
    super.key,
  });

  static const Duration _animationDuration = Duration(milliseconds: 1800);

  final CharacterIdentity identity;
  final int previousStage;
  final int newStage;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: <Widget>[
                    const Spacer(),
                    Text(
                      '진화 완료',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _EvolutionSprite(
                      identity: identity,
                      previousStage: previousStage,
                      newStage: newStage,
                      disableAnimations: disableAnimations,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      identity.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      stageName(identity.species, newStage),
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: t.brandLight),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('닫기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionSprite extends StatelessWidget {
  const _EvolutionSprite({
    required this.identity,
    required this.previousStage,
    required this.newStage,
    required this.disableAnimations,
  });

  final CharacterIdentity identity;
  final int previousStage;
  final int newStage;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 240,
    child: TweenAnimationBuilder<double>(
      duration: disableAnimations
          ? Duration.zero
          : EvolutionPage._animationDuration,
      tween: Tween<double>(begin: disableAnimations ? 1 : 0, end: 1),
      builder: (context, progress, _) {
        final showingNewStage = disableAnimations || progress >= 0.5;
        final phase = showingNewStage ? (progress - 0.5) * 2 : progress * 2;
        final opacity = (showingNewStage ? phase : 1 - phase).clamp(0.0, 1.0);
        final scale = showingNewStage ? 0.75 + phase * 0.25 : 1 + phase * 0.2;
        final flash = (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
        final stage = showingNewStage ? newStage : previousStage;
        final t = context.tokens;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Opacity(
              opacity: flash * 0.7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.brandLight,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 232),
              ),
            ),
            Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Image.asset(
                  stageAsset(identity.species, stage),
                  key: Key('evolution-stage-$stage'),
                  width: 192,
                  height: 192,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.pets_rounded, size: 112, color: t.brand),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
