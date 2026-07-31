import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/formatting/app_format.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../exercise_db/presentation/widgets/exercise_thumbnail.dart';
import 'set_table_header.dart';

class ExerciseBlock extends StatelessWidget {
  const ExerciseBlock({
    required this.name,
    required this.exerciseId,
    required this.equipment,
    this.thumbnailUrl,
    required this.setRows,
    required this.onAddSet,
    this.weightUnit = WeightUnit.kg,
    super.key,
  });

  final String name;
  final String exerciseId;
  final Equipment equipment;
  final String? thumbnailUrl;
  final List<Widget> setRows;
  final VoidCallback onAddSet;
  final WeightUnit weightUnit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: <Widget>[
                ExerciseThumbnail(
                  equipment: equipment,
                  thumbnailUrl: thumbnailUrl,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          SetTableHeader(weightUnit: weightUnit),
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
