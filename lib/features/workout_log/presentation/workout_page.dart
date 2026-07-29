import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/routine.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_set.dart';
import '../../routine/application/routine_providers.dart';
import '../../stats/application/stats_providers.dart';
import '../../exercise_db/application/exercise_providers.dart';
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
  final Map<String, Exercise> _selectedExercises = <String, Exercise>{};
  final Map<String, int> _extraDrafts = <String, int>{};
  final Map<String, _SetDraft> _drafts = <String, _SetDraft>{};

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSessionProvider);
    return active.when(
      loading: () => const Scaffold(body: AppLoading()),
      error: (_, _) =>
          Scaffold(body: Center(child: Text(context.l10n.workoutInProgress))),
      data: (result) => result.when(ok: _activeView, err: (_) => _startView()),
    );
  }

  Future<void> _start() async {
    await ref.read(workoutSessionControllerProvider).startSession();
    ref.invalidate(activeSessionProvider);
  }

  Widget _startView() {
    final t = context.tokens;
    final weekly = ref.watch(weeklyVolumeProvider());
    final routines = ref.watch(routinesProvider);
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(context.l10n.todayWorkout)),
      backgroundColor: t.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _StartHero(onStart: _start),
          const SizedBox(height: 16),
          weekly.when(
            loading: () => const SizedBox(height: 74),
            error: (_, _) => const SizedBox.shrink(),
            data: (result) => result.when(
              ok: (volumes) => _WeekStat(volumes: volumes),
              err: (_) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Text(
                '내 루틴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: t.text,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/routines'),
                child: const Text('전체'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          routines.when(
            loading: () => const AppLoading(),
            error: (_, _) => const SizedBox.shrink(),
            data: (result) => result.when(
              ok: (items) => _RoutineList(
                routines: items,
                onOpen: (routine) =>
                    context.push('/routines/detail/${routine.id}'),
              ),
              err: (_) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeView(WorkoutSession session) {
    final sets = ref.watch(sessionSetsProvider(session.id));
    final timer = ref.watch(restTimerProvider);
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(context.l10n.todayWorkout)),
      body: sets.when(
        loading: () => const AppLoading(),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => _sessionList(session, items, timer),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton.icon(
          key: const Key('finish-workout'),
          onPressed: () => _end(session),
          icon: const Icon(Icons.check),
          label: Text(context.l10n.endWorkout),
        ),
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
        final selected = _selectedExercises[entry.key];
        final metadata = ref
            .watch(exerciseByIdProvider(entry.key))
            .valueOrNull
            ?.when(ok: (value) => value, err: (_) => null);
        final exercise = selected ?? metadata;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ExerciseBlock(
            key: Key('exercise-block-${entry.key}'),
            name: name,
            exerciseId: entry.key,
            equipment: exercise?.equipment ?? Equipment.other,
            thumbnailUrl: exercise?.thumbnailUrl,
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
    final count = _extraDrafts[exerciseId] ?? 0;
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
        _selectedExercises[exercise.id] = exercise;
        final prefill = prefillForExercise(sets, exercise.id);
        _drafts['${exercise.id}-0'] = _SetDraft(prefill.weight, prefill.reps);
        // 종목 추가 시 기록할 첫 세트 한 줄을 보여준다.
        _extraDrafts[exercise.id] = 1;
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
      ok: (_) => setState(() {
        _drafts.removeWhere((_, value) => identical(value, draft));
        // 완료된 세트는 커밋되어 목록에 남으므로 draft 한 줄을 줄인다.
        final remaining = (_extraDrafts[exerciseId] ?? 1) - 1;
        _extraDrafts[exerciseId] = remaining < 0 ? 0 : remaining;
      }),
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

/// 빈 세션으로 바로 시작하는 히어로 CTA 카드(잉크블랙).
class _StartHero extends StatelessWidget {
  const _StartHero({required this.onStart});

  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.text,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '새 운동 시작',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: t.onBrand,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '빈 세션으로 바로 기록',
                      style: TextStyle(
                        fontSize: 13,
                        color: t.onBrand.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.onBrand.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: t.onBrand,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이번 주 요약(볼륨·운동일).
class _WeekStat extends StatelessWidget {
  const _WeekStat({required this.volumes});

  final Map<DateTime, double> volumes;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = volumes.values.fold<double>(0, (sum, v) => sum + v);
    final days = volumes.values.where((v) => v > 0).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: <Widget>[
          _stat(t, '이번 주 볼륨', '${formatCompactNumber(total)} kg'),
          Container(
            width: 0.5,
            height: 30,
            color: t.borderStrong.withValues(alpha: 0.4),
          ),
          _stat(t, '운동일', '$days일'),
        ],
      ),
    );
  }

  Widget _stat(AppTokens t, String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: t.faintText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            color: t.text,
          ),
        ),
      ],
    ),
  );
}

/// 내 루틴 카드 목록.
class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.routines, required this.onOpen});

  final List<Routine> routines;
  final ValueChanged<Routine> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (routines.isEmpty) {
      return Semantics(
        button: true,
        label: '루틴 만들기',
        child: Material(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => context.push('/routines'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border),
              ),
              child: Column(
                children: <Widget>[
                  Icon(Icons.add_rounded, color: t.mutedText, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    '루틴 만들기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final visible = routines.take(4).toList(growable: false);
    return Column(
      children: <Widget>[
        for (final routine in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RoutineCard(routine: routine, onTap: () => onOpen(routine)),
          ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.onTap});

  final Routine routine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: Icon(
                  Icons.list_alt_rounded,
                  color: t.mutedText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      routine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routine.description ?? '루틴',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: t.mutedText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.faintText),
            ],
          ),
        ),
      ),
    );
  }
}
