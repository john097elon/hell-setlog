import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/workout_set.dart';

/// 사람이 들 수 있는 범위. 오타로 볼륨 통계가 망가지지 않게 잘라 둔다.
double _clampWeight(double value) => value.clamp(0, 999);

/// 세트 한 줄. 커밋된 세트는 큰 정적 숫자로, 입력 중인 draft는 스텝퍼로 보여준다.
class SetRow extends StatefulWidget {
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
  final VoidCallback? onComplete;
  final WorkoutSet? set;
  final VoidCallback? onDelete;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  // 루틴이 미리 만들어 둔 계획 세트도 완료 전에는 실제 값으로 고칠 수 있어야 한다.
  bool get _isDraft => widget.set == null || !widget.set!.isCompleted;
  bool get _isDone => widget.set?.isCompleted == true;

  String get _weightText => widget.weight.toStringAsFixed(
    widget.weight == widget.weight.roundToDouble() ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: _weightText);
    _repsController = TextEditingController(text: '${widget.reps}');
  }

  @override
  void didUpdateWidget(covariant SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weight != widget.weight) {
      _syncController(_weightController, _weightText);
    }
    if (oldWidget.reps != widget.reps) {
      _syncController(_repsController, '${widget.reps}');
    }
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

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
              '${widget.index + 1}',
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
                    style: numberStyle,
                    onMinus: () => widget.onWeightChanged(
                      _clampWeight(widget.weight - 2.5),
                    ),
                    onPlus: () => widget.onWeightChanged(
                      _clampWeight(widget.weight + 2.5),
                    ),
                    controller: _weightController,
                    inputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        widget.onWeightChanged(_clampWeight(parsed));
                      }
                    },
                    fieldKey: const Key('set-weight-input'),
                    semanticLabel: '무게',
                  )
                : Center(child: Text(_weightText, style: numberStyle)),
          ),
          Expanded(
            child: _isDraft
                ? _Stepper(
                    style: numberStyle,
                    onMinus: () =>
                        widget.onRepsChanged((widget.reps - 1).clamp(0, 999)),
                    onPlus: () =>
                        widget.onRepsChanged((widget.reps + 1).clamp(0, 999)),
                    controller: _repsController,
                    inputType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        widget.onRepsChanged(parsed.clamp(0, 999));
                      }
                    },
                    fieldKey: const Key('set-reps-input'),
                    semanticLabel: '횟수',
                  )
                : Center(child: Text('${widget.reps}', style: numberStyle)),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              key: const Key('complete-set'),
              tooltip: context.l10n.completeSet,
              onPressed: widget.onComplete,
              icon: Icon(
                _isDone ? Icons.check_circle : Icons.check_circle_outline,
              ),
              color: _isDone ? scheme.primary : context.tokens.faintText,
            ),
          ),
        ],
      ),
    );
    if (widget.onDelete == null) return row;
    return Dismissible(
      key: Key('set-${widget.set!.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onDismissed: (_) => widget.onDelete!(),
      child: row,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.style,
    required this.onMinus,
    required this.onPlus,
    required this.controller,
    required this.inputType,
    required this.inputFormatters,
    required this.onChanged,
    required this.fieldKey,
    required this.semanticLabel,
  });
  final TextStyle? style;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final TextEditingController controller;
  final TextInputType inputType;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;
  final Key fieldKey;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _StepBtn(icon: Icons.remove, onTap: onMinus, label: '$semanticLabel 줄이기'),
      Expanded(
        child: TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          style: style,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
      _StepBtn(icon: Icons.add, onTap: onPlus, label: '$semanticLabel 늘리기'),
    ],
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.label,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  // 탭 영역은 48dp 이상이어야 한다. 보이는 사각형은 34dp로 두고 여백으로 넓힌다.
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
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
      ),
    ),
  );
}
