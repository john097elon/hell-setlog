import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../domain/entities/workout_set.dart';

class SetRow extends StatelessWidget {
  const SetRow({
    required this.index,
    required this.weight,
    required this.reps,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onComplete,
    this.set,
    this.onDelete,
    super.key,
  });

  final int index;
  final double weight;
  final int reps;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onComplete;
  final WorkoutSet? set;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final row = ListTile(
      title: Row(
        children: <Widget>[
          SizedBox(width: 30, child: Text('${index + 1}')),
          _Stepper(
            value: weight.toStringAsFixed(
              weight == weight.roundToDouble() ? 0 : 1,
            ),
            onMinus: () =>
                onWeightChanged((weight - 2.5).clamp(0, double.infinity)),
            onPlus: () => onWeightChanged(weight + 2.5),
          ),
          const SizedBox(width: 8),
          _Stepper(
            value: '$reps',
            onMinus: () => onRepsChanged((reps - 1).clamp(0, 999)),
            onPlus: () => onRepsChanged(reps + 1),
          ),
          IconButton(
            key: const Key('complete-set'),
            tooltip: context.l10n.completeSet,
            onPressed: onComplete,
            icon: Icon(
              set?.isCompleted == true
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
            ),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
    if (onDelete == null) return row;
    return Dismissible(
      key: Key('set-${set!.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => onDelete!(),
      child: row,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(onPressed: onMinus, icon: const Icon(Icons.remove)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
      ],
    ),
  );
}
