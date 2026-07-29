import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/routine_item.dart';
import '../../workout_log/presentation/widgets/exercise_picker_sheet.dart';
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
        title: Text(context.l10n.record),
        actions: <Widget>[
          TextButton(onPressed: _save, child: Text(context.l10n.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: context.l10n.record),
          ),
          const SizedBox(height: 16),
          if (items != null)
            items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
              data: (result) => result.when(
                ok: (value) => Column(
                  children: <Widget>[
                    for (final item in value) _RoutineItemEditor(item: item),
                    const SizedBox(height: 12),
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
    if (name.isEmpty) return;
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
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.exerciseId, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _NumberField(
                value: item.targetSets,
                label: context.l10n.setItem(item.targetSets),
                onChanged: (value) =>
                    _update(ref, item.copyWith(targetSets: value)),
              ),
              _NumberField(
                value: item.targetReps,
                label: context.l10n.completeSet,
                onChanged: (value) =>
                    _update(ref, item.copyWith(targetReps: value)),
              ),
              _NumberField(
                value: item.targetWeight,
                label: context.l10n.sampleSetDetails,
                onChanged: (value) =>
                    _update(ref, item.copyWith(targetWeight: value.toDouble())),
              ),
              IconButton(
                onPressed: () =>
                    ref.read(routineEditorControllerProvider).removeItem(item),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _update(WidgetRef ref, RoutineItem item) =>
      ref.read(routineEditorControllerProvider).updateItem(item);
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.value,
    required this.label,
    required this.onChanged,
  });
  final num value;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    child: TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onFieldSubmitted: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null && parsed >= 0) onChanged(parsed);
      },
    ),
  );
}
