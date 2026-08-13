import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/widgets/app_list.dart';
import 'package:heal_setlog/core/widgets/app_screen.dart';
import 'package:heal_setlog/core/widgets/app_states.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/features/settings/application/settings_controller.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';
import 'package:heal_setlog/features/stats/presentation/widgets/body_part_split.dart';
import 'package:heal_setlog/features/stats/presentation/widgets/summary_row.dart';
import 'package:heal_setlog/features/stats/presentation/widgets/weekly_volume_chart.dart';

/// 운동 기록을 종목별 기록 수와 웨이트 통계로 표시한다.
class StatsPage extends ConsumerWidget {
  const StatsPage({this.embedded = false, super.key});

  /// 운동 탭 안에 배치되는지 알려 주는 기존 호환 인자.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyVolumeProvider());
    final title = context.l10n.statsTitle;
    return weekly.when(
      data: (result) => result.when(
        ok: (volumes) => AppScreen(
          title: title,
          embedded: embedded,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: AppPagePadding(
                top: AppSpacing.sm,
                child: _StatsContent(volumes: volumes),
              ),
            ),
          ],
        ),
        err: (_) => AppScreen(
          title: title,
          embedded: embedded,
          slivers: const <Widget>[
            SliverFillRemaining(hasScrollBody: false, child: _StatsError()),
          ],
        ),
      ),
      loading: () => AppScreen(
        title: title,
        embedded: embedded,
        slivers: const <Widget>[
          SliverToBoxAdapter(
            child: AppPagePadding(top: AppSpacing.sm, child: _StatsSkeleton()),
          ),
        ],
      ),
      error: (_, _) => AppScreen(
        title: title,
        embedded: embedded,
        slivers: const <Widget>[
          SliverFillRemaining(hasScrollBody: false, child: _StatsError()),
        ],
      ),
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({required this.volumes});

  final Map<DateTime, double> volumes;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(weeklyDisciplineCountsProvider())
      .when(
        data: (result) => result.when(
          ok: (counts) => _StatsSections(volumes: volumes, counts: counts),
          err: (_) => volumes.values.any((value) => value > 0)
              ? _StatsSections(volumes: volumes, counts: const {})
              : const _StatsError(),
        ),
        loading: () => const _StatsSkeleton(),
        error: (_, _) => volumes.values.any((value) => value > 0)
            ? _StatsSections(volumes: volumes, counts: const {})
            : const _StatsError(),
      );
}

class _StatsSections extends ConsumerWidget {
  const _StatsSections({required this.volumes, required this.counts});

  final Map<DateTime, double> volumes;
  final Map<Discipline, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVolume = volumes.values.any((value) => value > 0);
    if (!hasVolume && counts.isEmpty) return const _EmptyStats();

    final bodyPart = hasVolume ? ref.watch(bodyPartSplitProvider()) : null;
    final weightUnit = ref.watch(
      settingsControllerProvider.select((state) => state.weightUnit),
    );
    final totalVolume = volumes.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final workoutDays = volumes.values.where((value) => value > 0).length;
    final activity = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (hasVolume) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(
              context.l10n.statsThisWeek,
              style: AppText.sectionLabel(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SummaryRow(
            workoutDays: workoutDays,
            totalVolume: totalVolume,
            weightUnit: weightUnit,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSection(
            title: context.l10n.statsWeeklyVolume,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: WeeklyVolumeChart(volumes: volumes),
              ),
            ],
          ),
          bodyPart!.when(
            data: (result) => result.when(
              ok: (split) => split.isEmpty
                  ? const SizedBox.shrink()
                  : AppSection(
                      title: context.l10n.statsBodyPartSplit,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: BodyPartSplit(volumes: split),
                        ),
                      ],
                    ),
              err: (_) => const _StatsError(compact: true),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl),
              child: AppSkeleton(height: 140, radius: AppRadius.md),
            ),
            error: (_, _) => const _StatsError(compact: true),
          ),
        ],
        if (activity.isNotEmpty)
          AppSection(
            title: context.l10n.statsDisciplineActivity,
            children: <Widget>[
              for (final entry in activity)
                AppRow(
                  title: disciplineLabel(entry.key),
                  value: context.l10n.statsRecordCount(entry.value),
                ),
            ],
          ),
      ],
    );
  }
}

/// 통계 첫 로딩 동안 실제 카드 크기를 미리 차지한다.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AppSkeleton(height: 18, width: 120),
      SizedBox(height: AppSpacing.md),
      AppSkeleton(height: 78, radius: AppRadius.md),
      SizedBox(height: AppSpacing.xl),
      AppSkeleton(height: 18, width: 140),
      SizedBox(height: AppSpacing.md),
      AppSkeleton(height: 200, radius: AppRadius.md),
      SizedBox(height: AppSpacing.xl),
      AppSkeleton(height: 18, width: 110),
      SizedBox(height: AppSpacing.md),
      AppSkeleton(height: 140, radius: AppRadius.md),
    ],
  );
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) => AppEmptyState(
    icon: Icons.bar_chart_rounded,
    title: context.l10n.statsNoData,
    message: context.l10n.statsNoDataDescription,
  );
}

class _StatsError extends StatelessWidget {
  const _StatsError({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(compact ? AppSpacing.xl : 0),
    child: Center(child: Text(context.l10n.statsLoadError)),
  );
}
