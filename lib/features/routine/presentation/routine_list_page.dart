import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../domain/entities/routine.dart';
import '../application/routine_editor_controller.dart';
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
        error: (_, _) => const SizedBox.shrink(),
        data: (result) => result.when(
          ok: (items) => items.isEmpty
              ? _EmptyRoutines(onCreate: () => context.push('/routines/edit/new'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _RoutineTile(
                    routine: items[index],
                    onStart: () => _start(context, ref, items[index]),
                    onEdit: () => context.push('/routines/edit/${items[index].id}'),
                    onDelete: () => _delete(context, ref, items[index]),
                  ),
                ),
          err: (failure) => Center(child: Text(failure.message)),
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, Routine routine) async {
    final result = await ref.read(startFromRoutineControllerProvider).start(routine.id);
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
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Routine routine) async {
    final result = await ref
        .read(routineEditorControllerProvider)
        .deleteRoutine(routine.id);
    if (!context.mounted) return;
    result.when(
      ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.setDeleted)),
      ),
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.format_list_bulleted_rounded,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(context.l10n.record, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(context.l10n.todayWorkoutDescription, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.create),
          ),
        ],
      ),
    ),
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
          IconButton(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded)),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    ),
  );
}
