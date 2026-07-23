import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';
import 'set_table_header.dart';

class ExerciseBlock extends StatelessWidget {
  const ExerciseBlock({
    required this.name,
    required this.setRows,
    required this.onAddSet,
    super.key,
  });

  final String name;
  final List<Widget> setRows;
  final VoidCallback onAddSet;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(name, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SetTableHeader(),
          ...setRows,
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: TextButton.icon(
              key: Key('add-set-$name'),
              onPressed: onAddSet,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addSet),
            ),
          ),
        ],
      ),
    ),
  );
}
