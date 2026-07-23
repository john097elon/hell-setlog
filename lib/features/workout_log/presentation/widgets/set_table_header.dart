import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';

class SetTableHeader extends StatelessWidget {
  const SetTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 42,
            child: Text(context.l10n.setColumn, style: style),
          ),
          Expanded(
            child: Center(child: Text(context.l10n.weightKg, style: style)),
          ),
          Expanded(
            child: Center(child: Text(context.l10n.reps, style: style)),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
