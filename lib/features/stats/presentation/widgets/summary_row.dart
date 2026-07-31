import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

/// 이번 주 운동 기록의 핵심 수치를 표시한다.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.workoutDays,
    required this.totalVolume,
    required this.weightUnit,
    super.key,
  });

  final int workoutDays;
  final double totalVolume;
  final WeightUnit weightUnit;

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
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center_rounded,
            label: copy.statsTotalVolume,
            value: formatWeightWithUnit(totalVolume, unit: weightUnit),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: context.tokens.brand),
          const SizedBox(height: AppSpacing.lg),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontFeatures: kTabularFigures),
          ),
        ],
      ),
    ),
  );
}
