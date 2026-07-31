import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/personal_record.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../../../domain/entities/routine.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_set.dart';
import '../../party/application/party_providers.dart';
import '../../routine/application/routine_providers.dart';
import '../../stats/application/stats_providers.dart';
import '../../character/application/character_providers.dart';
import '../../character/presentation/evolution_page.dart';
import '../../exercise_db/application/exercise_providers.dart';
import '../application/exercise_name_provider.dart';
import '../application/rest_timer_controller.dart';
import '../application/workout_providers.dart';
import '../application/workout_session_controller.dart';
import 'models/share_view_data.dart';
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
  // 종목별 입력 중인 세트 줄. 순서가 곧 화면 순서라 완료된 줄만 빼면 나머지 입력값이 남는다.
  final Map<String, List<_SetDraft>> _drafts = <String, List<_SetDraft>>{};
  bool _isStarting = false;

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
    if (_isStarting) return;
    setState(() => _isStarting = true);
    final result = await ref
        .read(workoutSessionControllerProvider)
        .startSession();
    // 시작 직후 탭을 옮기면 dispose된 ref를 쓰게 된다.
    if (!mounted) return;
    setState(() => _isStarting = false);
    result.when(
      ok: (_) => ref.invalidate(activeSessionProvider),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
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
          _StartHero(onStart: _isStarting ? null : _start),
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
    for (final exerciseId in _drafts.keys) {
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
            onAddSet: () => setState(() => _addDraft(entry.key, entry.value)),
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
          onWeightChanged: (value) => _updatePlanned(set, weight: value),
          onRepsChanged: (value) => _updatePlanned(set, reps: value),
          onComplete: set.isCompleted ? () {} : () => _completeExisting(set),
          onDelete: () => _delete(set),
        ),
      );
    }
    final drafts = _drafts[exerciseId] ?? const <_SetDraft>[];
    for (var index = 0; index < drafts.length; index++) {
      final draft = drafts[index];
      rows.add(
        SetRow(
          // 줄이 사라져도 입력값이 섞이지 않도록 draft 객체를 키로 쓴다.
          key: ObjectKey(draft),
          index: sets.length + index,
          weight: draft.weight,
          reps: draft.reps,
          onWeightChanged: (value) => setState(() => draft.weight = value),
          onRepsChanged: (value) => setState(() => draft.reps = value),
          // 저장 중 연타로 같은 세트가 두 번 기록되던 자리.
          onComplete: draft.isSaving
              ? null
              : () => _completeDraft(session, exerciseId, draft),
        ),
      );
    }
    return rows;
  }

  void _updatePlanned(WorkoutSet set, {double? weight, int? reps}) {
    if (set.isCompleted) return;
    ref
        .read(workoutSessionControllerProvider)
        .updatePlannedSet(set, weight: weight, reps: reps);
  }

  void _addDraft(String exerciseId, List<WorkoutSet> sets) {
    final prefill = prefillForExercise(sets, exerciseId);
    _drafts
        .putIfAbsent(exerciseId, () => <_SetDraft>[])
        .add(_SetDraft(prefill.weight, prefill.reps));
  }

  void _pickExercise(List<WorkoutSet> sets) =>
      showExercisePickerSheet(context, (Exercise exercise) {
        _selectedExerciseNames[exercise.id] = exercise.nameKo;
        _selectedExercises[exercise.id] = exercise;
        // 종목 추가 시 기록할 첫 세트 한 줄을 보여준다.
        if (_drafts[exercise.id]?.isEmpty ?? true) {
          _addDraft(exercise.id, sets);
        }
        setState(() {});
      });

  Future<void> _completeDraft(
    WorkoutSession session,
    String exerciseId,
    _SetDraft draft,
  ) async {
    if (draft.isSaving) return;
    setState(() => draft.isSaving = true);
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
      // 완료된 세트는 커밋되어 목록에 남으므로 해당 draft 한 줄만 걷어낸다.
      ok: (_) => setState(
        () => _drafts[exerciseId]?.removeWhere((row) => identical(row, draft)),
      ),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
    if (mounted) setState(() => draft.isSaving = false);
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

  Future<void> _delete(WorkoutSet set) async {
    final result = await ref
        .read(workoutSessionControllerProvider)
        .deleteSet(set.id);
    if (!mounted) return;
    // 삭제가 실패했는데도 성공 메시지와 되돌리기를 보여주던 자리.
    result.when(
      ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.setDeleted),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () =>
                ref.read(workoutSessionControllerProvider).restoreSet(set),
          ),
        ),
      ),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  /// 이번 세션에서 세운 기록 중 대표 하나를 문구로 만든다.
  String _prLabel(List<PersonalRecord> records) {
    final oneRm = records.where((record) => record.type == PrType.oneRm);
    final best = (oneRm.isNotEmpty ? oneRm : records).reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return switch (best.type) {
      PrType.oneRm => '1RM ${formatWeight(best.value)}kg 신기록',
      PrType.volume => '볼륨 ${formatWeight(best.value)}kg 신기록',
      PrType.reps => '${best.value.round()}회 신기록',
    };
  }

  Future<void> _end(WorkoutSession session) async {
    // 종료 전 지표를 계산해 공유 시트에 넘긴다.
    final sets =
        ref.read(sessionSetsProvider(session.id)).valueOrNull ??
        const <WorkoutSet>[];
    // 세션 볼륨과 같은 기준. 준비 세트는 빼야 수치가 어긋나지 않는다.
    final completed = sets.where((set) => set.isCompleted && !set.isWarmup);
    final volume = completed.fold<double>(
      0,
      (sum, set) => sum + set.weight * set.reps,
    );
    final minutes = DateTime.now().difference(session.startedAt).inMinutes;
    final tags = <String>[
      if (volume > 0) '${formatWeight(volume)} kg',
      if (minutes > 0) '$minutes분',
      '${completed.length}세트',
    ];
    final result = await ref
        .read(workoutSessionControllerProvider)
        .endSession(session.id);
    if (!mounted) return;
    final failure = result.when(ok: (_) => null, err: (value) => value);
    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    // 다음 세션에 지난 종목·입력 줄이 남아 보이지 않게 화면 상태를 비운다.
    setState(() {
      _selectedExerciseNames.clear();
      _selectedExercises.clear();
      _drafts.clear();
    });
    ref
      ..invalidate(activeSessionProvider)
      // 종료했는데 통계와 캐릭터가 이전 값 그대로였다.
      ..invalidate(weeklyVolumeProvider)
      ..invalidate(bodyPartSplitProvider)
      ..invalidate(characterVolumesProvider)
      ..invalidate(characterWeeklyVolumesProvider);
    final prLabel = await _updatePersonalRecords(session.id);
    final xp = xpForVolume(volume);
    // 파티 주간 미션은 파티에 남긴 활동으로 계산한다.
    await _recordToParties(session.id, volume, xp);
    if (!mounted) return;
    await showPendingCharacterEvolution(context, ref);
    if (!mounted) return;
    showShareWorkoutSheet(
      context,
      data: ShareViewData(
        workoutTags: tags,
        sessionId: session.id,
        volumeKg: volume > 0 ? volume : null,
        durationMin: minutes > 0 ? minutes : null,
        prLabel: prLabel,
        xp: xp > 0 ? xp : null,
      ),
    );
  }

  /// 내가 속한 파티들에 이번 운동을 남긴다. 실패해도 종료를 막지 않는다.
  Future<void> _recordToParties(String sessionId, double volume, int xp) async {
    try {
      final repository = ref.read(partyRepositoryProvider);
      await repository.recordActivity(
        sessionId: sessionId,
        volumeKg: volume,
        xp: xp,
      );
      // 파티원이 내 캐릭터를 볼 수 있게 성장 수치도 올린다.
      final growth = await ref.read(characterGrowthProvider.future);
      await repository.publishCharacterStats(
        level: growth.totalLevel,
        stage: growth.evolutionStage,
        xp: growth.totalXp,
      );
      ref.invalidate(myPartiesProvider);
    } on Object {
      // 네트워크가 없으면 다음 기회에 올린다.
    }
  }

  /// 개인 기록을 갱신하고 대표 기록 문구를 돌려준다. 실패해도 종료를 막지 않는다.
  Future<String?> _updatePersonalRecords(String sessionId) async {
    try {
      final records = await ref
          .read(statsRepositoryProvider)
          .updateRecordsForSession(sessionId);
      return records.when(
        ok: (values) => values.isEmpty ? null : _prLabel(values),
        err: (_) => null,
      );
    } on Object {
      return null;
    }
  }
}

class _SetDraft {
  _SetDraft(this.weight, this.reps);

  double weight;
  int reps;
  bool isSaving = false;
}

/// 빈 세션으로 바로 시작하는 히어로 CTA 카드(잉크블랙).
class _StartHero extends StatelessWidget {
  const _StartHero({required this.onStart});

  final Future<void> Function()? onStart;

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
