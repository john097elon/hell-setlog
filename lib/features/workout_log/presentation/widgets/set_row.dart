import 'package:flutter/material.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/workout_set.dart';

/// 세트 한 줄. 커밋된 세트는 큰 정적 숫자로, 입력 중인 draft는 스텝퍼로 보여준다.
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

  bool get _isDraft => set == null;
  bool get _isDone => set?.isCompleted == true;

  String get _weightText =>
      weight.toStringAsFixed(weight == weight.roundToDouble() ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final numberStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontFeatures: kTabularFigures,
      color: _isDone ? scheme.primary : context.tokens.text,
    );

    final row = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _isDone
            ? scheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 42,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.tokens.mutedText,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
          Expanded(
            child: _isDraft
                ? _Stepper(
                    value: _weightText,
                    style: numberStyle,
                    onMinus: () => onWeightChanged(
                      (weight - 2.5).clamp(0, double.infinity),
                    ),
                    onPlus: () => onWeightChanged(weight + 2.5),
                  )
                : Center(child: Text(_weightText, style: numberStyle)),
          ),
          Expanded(
            child: _isDraft
                ? _Stepper(
                    value: '$reps',
                    style: numberStyle,
                    onMinus: () => onRepsChanged((reps - 1).clamp(0, 999)),
                    onPlus: () => onRepsChanged(reps + 1),
                  )
                : Center(child: Text('$reps', style: numberStyle)),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              key: const Key('complete-set'),
              tooltip: context.l10n.completeSet,
              onPressed: onComplete,
              icon: Icon(
                _isDone ? Icons.check_circle : Icons.check_circle_outline,
              ),
              color: _isDone ? scheme.primary : context.tokens.faintText,
            ),
          ),
        ],
      ),
    );
    if (onDelete == null) return row;
    return Dismissible(
      key: Key('set-${set!.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onDismissed: (_) => onDelete!(),
      child: row,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.style,
    required this.onMinus,
    required this.onPlus,
  });
  final String value;
  final TextStyle? style;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _StepBtn(icon: Icons.remove, onTap: onMinus),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: style,
        ),
      ),
      _StepBtn(icon: Icons.add, onTap: onPlus),
    ],
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 22,
    child: Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.tokens.border),
      ),
      child: Icon(icon, size: 18, color: context.tokens.mutedText),
    ),
  );
}
