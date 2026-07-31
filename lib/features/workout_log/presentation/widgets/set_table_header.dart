import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_list.dart';

class SetTableHeader extends StatelessWidget {
  const SetTableHeader({this.weightUnit = WeightUnit.kg, super.key});

  final WeightUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    final style = AppText.metricLabel(context);
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
            child: Center(
              child: Text(weightUnit.name.toUpperCase(), style: style),
            ),
          ),
          Expanded(
            child: Center(child: Text(context.l10n.reps, style: style)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
