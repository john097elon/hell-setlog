import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// 이번 주 운동 기록의 핵심 수치를 표시한다.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.workoutDays,
    required this.totalVolume,
    super.key,
  });

  final int workoutDays;
  final double totalVolume;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryCard(
            icon: Icons.calendar_month_rounded,
            label: copy.statsWorkoutDays,
            value: copy.statsWorkoutDaysValue(workoutDays),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center_rounded,
            label: copy.statsTotalVolume,
            value: copy.statsVolumeValue(totalVolume.toStringAsFixed(0)),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}
