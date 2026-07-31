import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/widgets/app_screen.dart';

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
    return AppMetricRow(
      metrics: <AppMetric>[
        AppMetric(
          label: copy.statsWorkoutDays,
          value: copy.statsWorkoutDaysValue(workoutDays),
          size: 26,
        ),
        AppMetric(
          label: copy.statsTotalVolume,
          value: formatWeightWithUnit(totalVolume, unit: weightUnit),
          size: 26,
        ),
      ],
    );
  }
}
