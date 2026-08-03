import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_list.dart';
import '../../../../domain/entities/discipline.dart';

class SetTableHeader extends StatelessWidget {
  const SetTableHeader({
    required this.discipline,
    this.weightUnit = WeightUnit.kg,
    super.key,
  });

  final Discipline discipline;
  final WeightUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    final style = AppText.metricLabel(context);
    final (firstLabel, secondLabel) = switch (trackingModeOf(discipline)) {
      TrackingMode.setsReps => (
        weightUnit.name.toUpperCase(),
        context.l10n.reps,
      ),
      TrackingMode.distanceDuration => (
        discipline == Discipline.swimming ? '거리(M)' : '거리(KM)',
        '시간(분)',
      ),
      TrackingMode.durationIntensity => ('시간(분)', '강도(1–5)'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: AppSpacing.xxl,
            child: Text(
              context.l10n.setColumn,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            child: Center(child: Text(firstLabel, style: style)),
          ),
          Expanded(
            child: Center(child: Text(secondLabel, style: style)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
