import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_set.dart';
import '../application/rest_timer_controller.dart';
import '../application/workout_providers.dart';
import '../application/workout_session_controller.dart';
import 'widgets/exercise_picker_sheet.dart';
import 'widgets/rest_timer_bar.dart';
import 'widgets/set_row.dart';
import 'share_workout_sheet.dart';

/// Local-first workout recording screen.
class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({this.embedded = false, super.key});

  /// 운동 탭 안에 배치될 때 내부 앱 바를 숨긴다.
  final bool embedded;
  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  Exercise? _exercise;
  double _weight = 0;
  int _reps = 0;

  void _selectExercise(Exercise exercise, List<WorkoutSet> sets) {
    final prefill = prefillForExercise(sets, exercise.id);
    setState(() {
      _exercise = exercise;
      _weight = prefill.weight;
      _reps = prefill.reps;
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSessionProvider);
    return active.when(
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (_, _) =>
          Scaffold(body: Center(child: Text(context.l10n.workoutInProgress))),
      data: (result) =>
          result.when(ok: _activeView, err: (_) => _startView(context)),
    );
  }

  Widget _startView(BuildContext context) => Scaffold(
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
                  onPressed: () async {
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
                  },
                  child: Text(context.l10n.endWorkout),
                ),
              ],
            ),
      body: sets.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => Column(
          children: <Widget>[
            RestTimerBar(
              state: timer,
              onAdd: () => ref.read(restTimerProvider.notifier).addSeconds(),
              onSkip: () => ref.read(restTimerProvider.notifier).skip(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _exercise?.nameKo ?? context.l10n.selectExercise,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => showExercisePickerSheet(
                      context,
                      (exercise) => _selectExercise(exercise, items),
                    ),
                    child: Text(context.l10n.selectExercise),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length + (_exercise == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return SetRow(
                      index: items
                          .where((set) => set.exerciseId == _exercise!.id)
                          .length,
                      weight: _weight,
                      reps: _reps,
                      onWeightChanged: (value) =>
                          setState(() => _weight = value),
                      onRepsChanged: (value) => setState(() => _reps = value),
                      onComplete: () async {
                        await ref
                            .read(workoutSessionControllerProvider)
                            .completeDraft(
                              sessionId: session.id,
                              exerciseId: _exercise!.id,
                              weight: _weight,
                              reps: _reps,
                            );
                      },
                    );
                  }
                  final set = items[index];
                  return SetRow(
                    index: set.setIndex,
                    weight: set.weight,
                    reps: set.reps,
                    set: set,
                    onWeightChanged: (_) {},
                    onRepsChanged: (_) {},
                    onComplete: () {},
                    onDelete: () => _delete(set),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
}
