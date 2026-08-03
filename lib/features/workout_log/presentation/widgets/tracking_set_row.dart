import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/discipline.dart';
import '../../../../domain/entities/workout_set.dart';
import 'set_row.dart';

/// 종목의 기록 방식에 맞는 한 줄 입력판을 고른다.
class TrackingSetRow extends StatelessWidget {
  const TrackingSetRow({
    required this.index,
    required this.discipline,
    required this.weight,
    required this.reps,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.intensity,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onDistanceChanged,
    required this.onDurationChanged,
    required this.onIntensityChanged,
    required this.onComplete,
    this.set,
    this.onDelete,
    this.weightUnit = WeightUnit.kg,
    super.key,
  });

  final int index;
  final Discipline discipline;
  final double weight;
  final int reps;
  final double? distanceMeters;
  final int? durationSeconds;
  final int? intensity;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double?> onDistanceChanged;
  final ValueChanged<int?> onDurationChanged;
  final ValueChanged<int> onIntensityChanged;
  final VoidCallback? onComplete;
  final WorkoutSet? set;
  final VoidCallback? onDelete;
  final WeightUnit weightUnit;

  bool get _isCompleted => set?.isCompleted == true;

  @override
  Widget build(BuildContext context) => switch (trackingModeOf(discipline)) {
    TrackingMode.setsReps => SetRow(
      index: index,
      weight: weight,
      reps: reps,
      onWeightChanged: onWeightChanged,
      onRepsChanged: onRepsChanged,
      onComplete: onComplete,
      set: set,
      onDelete: onDelete,
      weightUnit: weightUnit,
    ),
    TrackingMode.distanceDuration => _DistanceDurationRow(
      index: index,
      discipline: discipline,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      isCompleted: _isCompleted,
      set: set,
      onDistanceChanged: onDistanceChanged,
      onDurationChanged: onDurationChanged,
      onComplete: (distanceMeters ?? 0) > 0 ? onComplete : null,
      onDelete: onDelete,
    ),
    TrackingMode.durationIntensity => _DurationIntensityRow(
      index: index,
      durationSeconds: durationSeconds,
      intensity: intensity ?? 3,
      isCompleted: _isCompleted,
      set: set,
      onDurationChanged: onDurationChanged,
      onIntensityChanged: onIntensityChanged,
      onComplete: (durationSeconds ?? 0) > 0 ? onComplete : null,
      onDelete: onDelete,
    ),
  };
}

class _DistanceDurationRow extends StatefulWidget {
  const _DistanceDurationRow({
    required this.index,
    required this.discipline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isCompleted,
    required this.set,
    required this.onDistanceChanged,
    required this.onDurationChanged,
    required this.onComplete,
    required this.onDelete,
  });

  final int index;
  final Discipline discipline;
  final double? distanceMeters;
  final int? durationSeconds;
  final bool isCompleted;
  final WorkoutSet? set;
  final ValueChanged<double?> onDistanceChanged;
  final ValueChanged<int?> onDurationChanged;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  @override
  State<_DistanceDurationRow> createState() => _DistanceDurationRowState();
}

class _DistanceDurationRowState extends State<_DistanceDurationRow> {
  late final TextEditingController _distanceController;
  late final TextEditingController _durationController;

  bool get _usesKilometers => widget.discipline != Discipline.swimming;

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController(text: _distanceText);
    _durationController = TextEditingController(text: _durationText);
  }

  @override
  void didUpdateWidget(covariant _DistanceDurationRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.distanceMeters != widget.distanceMeters ||
        oldWidget.discipline != widget.discipline) {
      _syncController(_distanceController, _distanceText);
    }
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _syncController(_durationController, _durationText);
    }
  }

  String get _distanceText {
    final meters = widget.distanceMeters;
    if (meters == null) return '';
    return _trimNumber(_usesKilometers ? meters / 1000 : meters);
  }

  String get _durationText {
    final seconds = widget.durationSeconds;
    return seconds == null ? '' : _trimNumber(seconds / 60);
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pace = _paceText(
      distanceMeters: widget.distanceMeters,
      durationSeconds: widget.durationSeconds,
      perHundredMeters: !_usesKilometers,
    );
    return _SwipeableTrackingRow(
      index: widget.index,
      isCompleted: widget.isCompleted,
      set: widget.set,
      onComplete: widget.onComplete,
      onDelete: widget.onDelete,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: widget.isCompleted
                    ? _StaticValue(
                        value: _distanceText,
                        suffix: _usesKilometers ? 'km' : 'm',
                      )
                    : _NumberField(
                        key: const Key('set-distance-input'),
                        controller: _distanceController,
                        semanticLabel: '거리',
                        suffix: _usesKilometers ? 'km' : 'm',
                        onChanged: (text) {
                          final value = double.tryParse(text);
                          widget.onDistanceChanged(
                            value == null
                                ? null
                                : value * (_usesKilometers ? 1000 : 1),
                          );
                        },
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: widget.isCompleted
                    ? _StaticValue(value: _durationText, suffix: '분')
                    : _NumberField(
                        key: const Key('set-duration-input'),
                        controller: _durationController,
                        semanticLabel: '시간',
                        suffix: '분',
                        onChanged: (text) {
                          final value = double.tryParse(text);
                          widget.onDurationChanged(
                            value == null ? null : (value * 60).round(),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (pace != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pace,
                key: const Key('set-pace'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.tokens.mutedText,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DurationIntensityRow extends StatefulWidget {
  const _DurationIntensityRow({
    required this.index,
    required this.durationSeconds,
    required this.intensity,
    required this.isCompleted,
    required this.set,
    required this.onDurationChanged,
    required this.onIntensityChanged,
    required this.onComplete,
    required this.onDelete,
  });

  final int index;
  final int? durationSeconds;
  final int intensity;
  final bool isCompleted;
  final WorkoutSet? set;
  final ValueChanged<int?> onDurationChanged;
  final ValueChanged<int> onIntensityChanged;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  @override
  State<_DurationIntensityRow> createState() => _DurationIntensityRowState();
}

class _DurationIntensityRowState extends State<_DurationIntensityRow> {
  late final TextEditingController _durationController;

  String get _durationText => widget.durationSeconds == null
      ? ''
      : _trimNumber(widget.durationSeconds! / 60);

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: _durationText);
  }

  @override
  void didUpdateWidget(covariant _DurationIntensityRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _syncController(_durationController, _durationText);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SwipeableTrackingRow(
    index: widget.index,
    isCompleted: widget.isCompleted,
    set: widget.set,
    onComplete: widget.onComplete,
    onDelete: widget.onDelete,
    footer: widget.isCompleted
        ? null
        : Row(
            key: const Key('set-intensity-input'),
            children: <Widget>[
              for (var value = 1; value <= 5; value++) ...<Widget>[
                if (value > 1) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _IntensityButton(
                    value: value,
                    selected: value == widget.intensity,
                    onTap: () => widget.onIntensityChanged(value),
                  ),
                ),
              ],
            ],
          ),
    child: widget.isCompleted
        ? Row(
            children: <Widget>[
              Expanded(
                child: _StaticValue(value: _durationText, suffix: '분'),
              ),
              Expanded(
                child: _StaticValue(value: '${widget.intensity}', suffix: '/5'),
              ),
            ],
          )
        : _NumberField(
            key: const Key('set-duration-input'),
            controller: _durationController,
            semanticLabel: '시간',
            suffix: '분',
            onChanged: (text) {
              final value = double.tryParse(text);
              widget.onDurationChanged(
                value == null ? null : (value * 60).round(),
              );
            },
          ),
  );
}

class _SwipeableTrackingRow extends StatelessWidget {
  const _SwipeableTrackingRow({
    required this.index,
    required this.isCompleted,
    required this.set,
    required this.onComplete,
    required this.onDelete,
    required this.child,
    this.footer,
  });

  final int index;
  final bool isCompleted;
  final WorkoutSet? set;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final row = Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: (isCompleted ? t.success : t.brand).withValues(alpha: 0.08),
        border: Border(
          left: BorderSide(color: isCompleted ? t.success : t.brand, width: 3),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? t.success.withValues(alpha: 0.14)
                        : t.brand,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isCompleted ? t.success : t.onBrand,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: child),
              SizedBox(
                width: 48,
                child: IconButton(
                  key: const Key('complete-set'),
                  tooltip: context.l10n.completeSet,
                  onPressed: onComplete,
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                  ),
                  color: isCompleted ? t.success : t.brand,
                ),
              ),
            ],
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            footer!,
          ],
        ],
      ),
    );
    if (onDelete == null || set == null) return row;
    return Dismissible(
      key: Key('set-${set!.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: Icon(Icons.delete_outline, color: t.like),
      ),
      onDismissed: (_) => onDelete!(),
      child: row,
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.semanticLabel,
    required this.suffix,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final String suffix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontFeatures: kTabularFigures),
      decoration: InputDecoration(
        isDense: true,
        suffixText: suffix,
        semanticCounterText: semanticLabel,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
      ),
    ),
  );
}

class _StaticValue extends StatelessWidget {
  const _StaticValue({required this.value, required this.suffix});

  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Center(
      child: Text(
        value.isEmpty ? '—' : '$value$suffix',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: context.tokens.mutedText,
          fontFeatures: kTabularFigures,
        ),
      ),
    ),
  );
}

class _IntensityButton extends StatelessWidget {
  const _IntensityButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: '강도 $value',
      child: Material(
        color: selected ? t.brand.withValues(alpha: 0.16) : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: selected ? t.brand : t.border),
        ),
        child: InkWell(
          key: Key('set-intensity-$value'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? t.brand : t.mutedText,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _syncController(TextEditingController controller, String value) {
  if (controller.text == value) return;
  controller.value = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );
}

String _trimNumber(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String? _paceText({
  required double? distanceMeters,
  required int? durationSeconds,
  required bool perHundredMeters,
}) {
  if (distanceMeters == null ||
      distanceMeters <= 0 ||
      durationSeconds == null ||
      durationSeconds <= 0) {
    return null;
  }
  final unitMeters = perHundredMeters ? 100 : 1000;
  final paceSeconds = (durationSeconds * unitMeters / distanceMeters).round();
  final minutes = paceSeconds ~/ 60;
  final seconds = paceSeconds % 60;
  return '페이스 $minutes:${seconds.toString().padLeft(2, '0')}'
      '${perHundredMeters ? '/100m' : '/km'}';
}
