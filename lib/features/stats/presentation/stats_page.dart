import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(
          context.l10n.statsThisWeek,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SummaryRow(workoutDays: workoutDays, totalVolume: totalVolume),
        const SizedBox(height: 28),
        Text(
          context.l10n.statsWeeklyVolume,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
            child: WeeklyVolumeChart(volumes: volumes),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          context.l10n.statsBodyPartSplit,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        bodyPart.when(
          data: (result) => result.when(
            ok: (split) => split.isEmpty
                ? const _EmptyStats(compact: true)
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BodyPartSplit(volumes: split),
                    ),
                  ),
            err: (_) => const _StatsError(compact: true),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const _StatsError(compact: true),
        ),
      ],
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.bar_chart_rounded,
            size: compact ? 32 : 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.statsNoData,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.statsNoDataDescription,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _StatsError extends StatelessWidget {
  const _StatsError({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(compact ? 24 : 0),
    child: Center(child: Text(context.l10n.statsLoadError)),
  );
}
