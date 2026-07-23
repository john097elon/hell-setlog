import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_set.dart';
import '../application/exercise_name_provider.dart';
import '../application/rest_timer_controller.dart';
import '../application/workout_providers.dart';
import '../application/workout_session_controller.dart';
import 'share_workout_sheet.dart';
import 'widgets/exercise_block.dart';
import 'widgets/exercise_picker_sheet.dart';
import 'widgets/rest_timer_bar.dart';
import 'widgets/set_row.dart';

/// Local-first workout recording screen.
class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({this.embedded = false, super.key});

  /// 운동 탭 안에 배치될 때 내부 앱 바를 숨긴다.
  final bool embedded;

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  final Map<String, String> _selectedExerciseNames = <String, String>{};
  final Map<String, int> _extraDrafts = <String, int>{};
  final Map<String, _SetDraft> _drafts = <String, _SetDraft>{};

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSessionProvider);
    return active.when(
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (_, _) =>
          Scaffold(body: Center(child: Text(context.l10n.workoutInProgress))),
      data: (result) => result.when(ok: _activeView, err: (_) => _startView()),
    );
  }

  Widget _startView() => Scaffold(
    appBar: widget.embedded
        ? null
        : AppBar(title: Text(context.l10n.todayWorkout)),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FilledButton.icon(
            onPressed: () async {
              await ref.read(workoutSessionControllerProvider).startSession();
              ref.invalidate(activeSessionProvider);
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(context.l10n.startWorkout),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/routines'),
            child: Text(context.l10n.record),
          ),
        ],
      ),
    ),
  );

  Widget _activeView(WorkoutSession session) {
    final sets = ref.watch(sessionSetsProvider(session.id));
    final timer = ref.watch(restTimerProvider);
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              actions: <Widget>[
                TextButton(
                  onPressed: () => _end(session),
                  child: Text(context.l10n.endWorkout),
                ),
              ],
            ),
      body: sets.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => _sessionList(session, items, timer),
      ),
    );
  }

  Widget _sessionList(
    WorkoutSession session,
    List<WorkoutSet> sets,
    RestTimerState timer,
  ) {
    final grouped = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      grouped.putIfAbsent(set.exerciseId, () => <WorkoutSet>[]).add(set);
    }
    for (final exerciseId in _selectedExerciseNames.keys) {
      grouped.putIfAbsent(exerciseId, () => <WorkoutSet>[]);
    }
    final entries = grouped.entries.toList(growable: false);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: entries.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return RestTimerBar(
            state: timer,
            onAdd: () => ref.read(restTimerProvider.notifier).addSeconds(),
            onSkip: () => ref.read(restTimerProvider.notifier).skip(),
          );
        }
        if (index == entries.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              key: const Key('add-exercise'),
              onPressed: () => _pickExercise(sets),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addExercise),
            ),
          );
        }
        final entry = entries[index - 1];
        final name =
            _selectedExerciseNames[entry.key] ??
            ref.watch(exerciseNameProvider(entry.key)).valueOrNull;
        if (name == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ExerciseBlock(
            key: Key('exercise-block-${entry.key}'),
            name: name,
            setRows: _rowsFor(session, entry.key, entry.value),
            onAddSet: () => setState(() {
              _extraDrafts.update(
                entry.key,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
            }),
          ),
        );
      },
    );
  }

  List<Widget> _rowsFor(
    WorkoutSession session,
    String exerciseId,
    List<WorkoutSet> sets,
  ) {
    final rows = <Widget>[];
    for (final set in sets) {
      rows.add(
        SetRow(
          index: set.setIndex,
          weight: set.weight,
          reps: set.reps,
          set: set,
          onWeightChanged: (_) {},
          onRepsChanged: (_) {},
          onComplete: set.isCompleted ? () {} : () => _completeExisting(set),
          onDelete: () => _delete(set),
        ),
      );
    }
    final count = (_extraDrafts[exerciseId] ?? 0) + 1;
    final prefill = prefillForExercise(sets, exerciseId);
    for (var index = 0; index < count; index++) {
      final key = '$exerciseId-$index';
      final draft = _drafts.putIfAbsent(
        key,
        () => _SetDraft(prefill.weight, prefill.reps),
      );
      rows.add(
        SetRow(
          index: sets.length + index,
          weight: draft.weight,
          reps: draft.reps,
          onWeightChanged: (value) => setState(() => draft.weight = value),
          onRepsChanged: (value) => setState(() => draft.reps = value),
          onComplete: () => _completeDraft(session, exerciseId, draft),
        ),
      );
    }
    return rows;
  }

  void _pickExercise(List<WorkoutSet> sets) =>
      showExercisePickerSheet(context, (Exercise exercise) {
        _selectedExerciseNames[exercise.id] = exercise.nameKo;
        final prefill = prefillForExercise(sets, exercise.id);
        _drafts['${exercise.id}-0'] = _SetDraft(prefill.weight, prefill.reps);
        setState(() {});
      });

  Future<void> _completeDraft(
    WorkoutSession session,
    String exerciseId,
    _SetDraft draft,
  ) async {
    final result = await ref
        .read(workoutSessionControllerProvider)
        .completeDraft(
          sessionId: session.id,
          exerciseId: exerciseId,
          weight: draft.weight,
          reps: draft.reps,
        );
    if (!mounted) return;
    result.when(
      ok: (_) => setState(
        () => _drafts.removeWhere((_, value) => identical(value, draft)),
      ),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  Future<void> _completeExisting(WorkoutSet set) async {
    final result = await ref
        .read(workoutSessionControllerProvider)
        .completeSet(set.id);
    if (!mounted) return;
    result.when(
      ok: (_) {},
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  void _delete(WorkoutSet set) {
    ref.read(workoutSessionControllerProvider).deleteSet(set.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.setDeleted),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () =>
              ref.read(workoutSessionControllerProvider).restoreSet(set),
        ),
      ),
    );
  }

  Future<void> _end(WorkoutSession session) async {
    final result = await ref
        .read(workoutSessionControllerProvider)
        .endSession(session.id);
    if (!mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(activeSessionProvider);
        showShareWorkoutSheet(context);
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _SetDraft {
  _SetDraft(this.weight, this.reps);

  double weight;
  int reps;
}
