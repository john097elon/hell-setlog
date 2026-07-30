import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/widgets/app_states.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';
import 'package:heal_setlog/features/stats/presentation/widgets/body_part_split.dart';
import 'package:heal_setlog/features/stats/presentation/widgets/summary_row.dart';
import 'package:heal_setlog/features/stats/presentation/widgets/weekly_volume_chart.dart';

/// 운동 기록을 주간 볼륨과 근육군 비중으로 표시한다.
class StatsPage extends ConsumerWidget {
  const StatsPage({this.embedded = false, super.key});

  /// 운동 탭 안에 배치될 때 내부 앱 바를 숨긴다.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyVolumeProvider());
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(context.l10n.statsTitle)),
      body: weekly.when(
        data: (result) => result.when(
          ok: (volumes) => volumes.isEmpty
              ? const _EmptyStats()
              : _StatsContent(volumes: volumes),
          err: (_) => const _StatsError(),
        ),
        loading: () => const _StatsSkeleton(),
        error: (_, _) => const _StatsError(),
      ),
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({required this.volumes});

  final Map<DateTime, double> volumes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyPart = ref.watch(bodyPartSplitProvider());
    final totalVolume = volumes.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final workoutDays = volumes.values.where((value) => value > 0).length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Text(
          context.l10n.statsThisWeek,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        SummaryRow(workoutDays: workoutDays, totalVolume: totalVolume),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.statsWeeklyVolume,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: WeeklyVolumeChart(volumes: volumes),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          context.l10n.statsBodyPartSplit,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        bodyPart.when(
          data: (result) => result.when(
            ok: (split) => split.isEmpty
                ? const _EmptyStats(compact: true)
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: BodyPartSplit(volumes: split),
                    ),
                  ),
            err: (_) => const _StatsError(compact: true),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: AppSkeleton(height: 140, radius: 16),
          ),
          error: (_, _) => const _StatsError(compact: true),
        ),
      ],
    );
  }
}

/// 통계 첫 로딩 동안 실제 카드 크기를 미리 차지한다.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    children: const <Widget>[
      AppSkeleton(height: 18, width: 120),
      SizedBox(height: AppSpacing.md),
      AppSkeleton(height: 78, radius: 16),
      SizedBox(height: AppSpacing.xxl),
      AppSkeleton(height: 18, width: 140),
      SizedBox(height: AppSpacing.md),
      AppSkeleton(height: 200, radius: 16),
      SizedBox(height: AppSpacing.xxl),
      AppSkeleton(height: 18, width: 110),
      SizedBox(height: AppSpacing.md),
      AppSkeleton(height: 140, radius: 16),
    ],
  );
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats({this.compact = false});

  final bool compact;

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
