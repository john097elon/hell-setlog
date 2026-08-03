import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_list.dart';
import '../../../../domain/entities/discipline.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../exercise_db/presentation/widgets/exercise_thumbnail.dart';
import 'set_table_header.dart';

class ExerciseBlock extends StatelessWidget {
  const ExerciseBlock({
    required this.name,
    required this.exerciseId,
    required this.equipment,
    required this.discipline,
    this.thumbnailUrl,
    required this.setRows,
    required this.onAddSet,
    this.weightUnit = WeightUnit.kg,
    super.key,
  });

  final String name;
  final String exerciseId;
  final Equipment equipment;
  final Discipline discipline;
  final String? thumbnailUrl;
  final List<Widget> setRows;
  final VoidCallback onAddSet;
  final WeightUnit weightUnit;

  @override
  Widget build(BuildContext context) => AppSection(
    margin: EdgeInsets.zero,
    children: <Widget>[
      AppRow(
        title: name,
        leading: ExerciseThumbnail(
          equipment: equipment,
          thumbnailUrl: thumbnailUrl,
          size: AppSpacing.xxl,
        ),
      ),
      SetTableHeader(discipline: discipline, weightUnit: weightUnit),
      ...setRows,
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: TextButton.icon(
          key: Key('add-set-$name'),
          onPressed: onAddSet,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.addSet),
        ),
      ),
    ],
  );
}
