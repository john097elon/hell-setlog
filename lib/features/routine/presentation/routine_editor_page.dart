import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/routine_item.dart';
import '../../workout_log/application/exercise_name_provider.dart';
import '../../workout_log/presentation/widgets/exercise_picker_sheet.dart';
import '../../settings/application/settings_controller.dart';
import '../application/routine_editor_controller.dart';
import '../application/routine_providers.dart';

class RoutineEditorPage extends ConsumerStatefulWidget {
  const RoutineEditorPage({required this.routineId, super.key});
  final String? routineId;

  @override
  ConsumerState<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends ConsumerState<RoutineEditorPage> {
  late final TextEditingController _nameController;
  String? _routineId;

  @override
  void initState() {
    super.initState();
    _routineId = widget.routineId;
    _nameController = TextEditingController();
    final id = _routineId;
    if (id != null) _loadName(id);
  }

  /// 기존 루틴을 열면 이름 칸이 비어 있어 저장이 조용히 무시되던 문제를 막는다.
  Future<void> _loadName(String routineId) async {
    final result = await ref.read(routinesProvider.future);
    if (!mounted) return;
    result.when(
      ok: (routines) {
        for (final routine in routines) {
          if (routine.id != routineId) continue;
          _nameController.text = routine.name;
          break;
        }
      },
      err: (_) {},
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routineId = _routineId;
    final items = routineId == null
        ? null
        : ref.watch(routineItemsProvider(routineId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 편집'),
        actions: <Widget>[
          TextButton(onPressed: _save, child: Text(context.l10n.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text('루틴 이름', style: AppText.sectionLabel(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: '루틴 이름'),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (items != null)
            items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
              data: (result) => result.when(
                ok: (value) => Column(
                  children: <Widget>[
                    for (final item in value) _RoutineItemEditor(item: item),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => _pickExercise(routineId!),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.l10n.selectExercise),
                    ),
                  ],
                ),
                err: (failure) => Text(failure.message),
              ),
            )
          else
            FilledButton(onPressed: _save, child: Text(context.l10n.save)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('루틴 이름을 입력해 주세요')));
      return;
    }
    final result = await ref
        .read(routineEditorControllerProvider)
        .saveRoutine(routineId: _routineId, name: name);
    if (!mounted) return;
    result.when(
      ok: (routine) {
        setState(() => _routineId = routine.id);
        context.go('/routines/edit/${routine.id}');
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  void _pickExercise(String routineId) =>
      showExercisePickerSheet(context, (Exercise exercise) async {
        await ref
            .read(routineEditorControllerProvider)
            .addItem(
              routineId: routineId,
              exerciseId: exercise.id,
              targetSets: 3,
              targetReps: 10,
              targetWeight: 0,
            );
      });
}

class _RoutineItemEditor extends ConsumerWidget {
  const _RoutineItemEditor({required this.item});
  final RoutineItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 화면에 UUID가 그대로 보이던 자리. 이름을 못 찾으면 중립 라벨로 둔다.
    final name =
        ref.watch(exerciseNameProvider(item.exerciseId)).valueOrNull ?? '종목';
    final weightUnit = ref.watch(
      settingsControllerProvider.select((state) => state.weightUnit),
    );
    return AppSection(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      children: <Widget>[
        AppRow(
          title: name,
          trailing: IconButton(
            tooltip: '종목 삭제',
            onPressed: () =>
                ref.read(routineEditorControllerProvider).removeItem(item),
            icon: Icon(Icons.delete_outline, color: context.tokens.like),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _NumberField(
                value: item.targetSets.toDouble(),
                label: '세트',
                onChanged: (value) =>
                    _update(ref, item.copyWith(targetSets: value.round())),
              ),
              _NumberField(
                value: item.targetReps.toDouble(),
                label: '횟수',
                onChanged: (value) =>
                    _update(ref, item.copyWith(targetReps: value.round())),
              ),
              _NumberField(
                key: ValueKey<String>('target-weight-${weightUnit.name}'),
                value: weightFromKg(item.targetWeight, weightUnit),
                label: '무게(${weightUnit.name})',
                // 2.5kg 같은 값이 잘리지 않도록 무게만 소수를 받는다.
                decimal: true,
                onChanged: (value) => _update(
                  ref,
                  item.copyWith(targetWeight: weightToKg(value, weightUnit)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _update(WidgetRef ref, RoutineItem item) =>
      ref.read(routineEditorControllerProvider).updateItem(item);
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.value,
    required this.label,
    required this.onChanged,
    this.decimal = false,
    super.key,
  });
  final double value;
  final String label;
  final ValueChanged<double> onChanged;
  final bool decimal;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: _text(widget.value),
  );

  String _text(double value) => widget.decimal && value != value.roundToDouble()
      ? value.toStringAsFixed(1)
      : value.round().toString();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 예전엔 엔터를 눌러야만 반영돼 값이 조용히 사라졌다. 칸을 벗어날 때도 저장한다.
  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0) {
      _controller.text = _text(widget.value);
      return;
    }
    if (_text(parsed) == _text(widget.value)) return;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    child: Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _commit();
      },
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(
            widget.decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
          ),
        ],
        style: const TextStyle(fontFeatures: kTabularFigures),
        decoration: InputDecoration(labelText: widget.label),
        onFieldSubmitted: (_) => _commit(),
      ),
    ),
  );
}
