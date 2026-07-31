import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/build_context_x.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/routine.dart';
import '../application/routine_editor_controller.dart';
import '../application/routine_presets.dart';
import '../application/routine_providers.dart';
import '../application/start_from_routine_controller.dart';

class RoutineListPage extends ConsumerWidget {
  const RoutineListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.record)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/routines/edit/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.create),
      ),
      body: routines.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('루틴을 불러오지 못했습니다')),
        data: (result) => result.when(
          ok: (items) => items.isEmpty
              ? const _EmptyRoutines()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _RoutineTile(
                    routine: items[index],
                    onStart: () => _start(context, ref, items[index]),
                    onEdit: () =>
                        context.push('/routines/edit/${items[index].id}'),
                    onDelete: () => _delete(context, ref, items[index]),
                  ),
                ),
          err: (failure) => Center(child: Text(failure.message)),
        ),
      ),
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final result = await ref
        .read(startFromRoutineControllerProvider)
        .start(routine.id);
    if (!context.mounted) return;
    result.when(
      ok: (outcome) async {
        if (!outcome.started) {
          final goToWorkout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(context.l10n.workoutInProgress),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.l10n.startWorkout),
                ),
              ],
            ),
          );
          if (goToWorkout != true || !context.mounted) return;
        }
        context.go('/workout');
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('‘${routine.name}’ 루틴을 삭제할까요?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(routineEditorControllerProvider)
        .deleteRoutine(routine.id);
    if (!context.mounted) return;
    result.when(
      ok: (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('루틴을 삭제했어요'))),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _EmptyRoutines extends ConsumerWidget {
  const _EmptyRoutines();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(routinePresetsProvider);
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Icon(Icons.format_list_bulleted_rounded, size: 48, color: t.brand),
        const SizedBox(height: 16),
        Text(
          '추천 루틴으로 시작',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '내게 맞는 루틴을 선택해 바로 기록을 시작하세요.',
          style: TextStyle(color: t.mutedText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        presets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _PresetMessage('추천 루틴을 불러오지 못했습니다'),
          data: (items) => items.isEmpty
              ? const _PresetMessage('추천 루틴을 준비 중입니다')
              : Column(
                  children: <Widget>[
                    for (final preset in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PresetCard(preset: preset),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _PresetCard extends ConsumerWidget {
  const _PresetCard({required this.preset});
  final RoutinePreset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: '${preset.name} 루틴 저장',
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _save(context, ref),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  preset.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(preset.description, style: TextStyle(color: t.mutedText)),
                const SizedBox(height: 10),
                Text(
                  '${preset.items.length}종목 · ${_levelLabel(preset.level)}',
                  style: TextStyle(color: t.faintText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(routineEditorControllerProvider);
    final created = await controller.saveRoutine(name: preset.name);
    final result = await created.when(
      ok: (routine) async {
        for (final item in preset.items) {
          final added = await controller.addItem(
            routineId: routine.id,
            exerciseId: item.exerciseId,
            targetSets: item.targetSets,
            targetReps: item.targetReps,
            targetWeight: item.targetWeight,
          );
          final failure = added.when(
            ok: (_) => null,
            err: (failure) => failure,
          );
          if (failure != null) return Err<Routine, Failure>(failure);
        }
        return Ok<Routine, Failure>(routine);
      },
      err: (failure) async => Err<Routine, Failure>(failure),
    );
    if (!context.mounted) return;
    result.when(
      ok: (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('추천 루틴을 저장했습니다'))),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _PresetMessage extends StatelessWidget {
  const _PresetMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(message, textAlign: TextAlign.center),
  );
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({
    required this.routine,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });
  final Routine routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      title: Text(routine.name),
      subtitle: routine.description == null ? null : Text(routine.description!),
      onTap: onEdit,
      trailing: Wrap(
        spacing: 4,
        children: <Widget>[
          IconButton(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}

String _levelLabel(String level) => switch (level) {
  'beginner' => '초급',
  'intermediate' => '중급',
  'advanced' => '고급',
  _ => level,
};
