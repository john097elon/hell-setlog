import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/build_context_x.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_states.dart';
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
    return AppScreen(
      title: context.l10n.routines,
      actions: <Widget>[
        IconButton(
          tooltip: context.l10n.create,
          onPressed: () => context.push('/routines/edit/new'),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      slivers: routines.when(
        loading: () => const <Widget>[
          SliverFillRemaining(hasScrollBody: false, child: AppLoading()),
        ],
        error: (_, _) => const <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('루틴을 불러오지 못했습니다')),
          ),
        ],
        data: (result) => result.when(
          ok: (items) => items.isEmpty
              ? const <Widget>[
                  SliverToBoxAdapter(
                    child: AppPagePadding(
                      top: AppSpacing.sm,
                      child: _EmptyRoutines(),
                    ),
                  ),
                ]
              : <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => _RoutineTile(
                        routine: items[index],
                        onStart: () => _start(context, ref, items[index]),
                        onEdit: () =>
                            context.push('/routines/edit/${items[index].id}'),
                        onDelete: () => _delete(context, ref, items[index]),
                      ),
                    ),
                  ),
                ],
          err: (failure) => <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(failure.message)),
            ),
          ],
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
    return Column(
      children: <Widget>[
        Icon(Icons.format_list_bulleted_rounded, size: 48, color: t.brand),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '추천 루틴으로 시작',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '내게 맞는 루틴을 선택해 바로 기록을 시작하세요.',
          style: TextStyle(color: t.mutedText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        presets.when(
          loading: () => const AppLoading(),
          error: (_, _) => const _PresetMessage('추천 루틴을 불러오지 못했습니다'),
          data: (items) => items.isEmpty
              ? const _PresetMessage('추천 루틴을 준비 중입니다')
              : AppSection(
                  children: <Widget>[
                    for (final preset in items) _PresetRow(preset: preset),
                  ],
                ),
        ),
      ],
    );
  }
}

class _PresetRow extends ConsumerWidget {
  const _PresetRow({required this.preset});
  final RoutinePreset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppRow(
    title: preset.name,
    subtitle: preset.description,
    value: '${preset.items.length}종목 · ${_levelLabel(preset.level)}',
    onTap: () => _save(context, ref),
  );

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
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Text(message, textAlign: TextAlign.center),
  );
}

enum _RoutineAction { edit, delete }

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
  Widget build(BuildContext context) => AppSection(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    children: <Widget>[
      AppRow(
        title: routine.name,
        subtitle: routine.description,
        onTap: onEdit,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: '루틴 시작',
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            PopupMenuButton<_RoutineAction>(
              tooltip: '루틴 메뉴',
              onSelected: (action) => switch (action) {
                _RoutineAction.edit => onEdit(),
                _RoutineAction.delete => onDelete(),
              },
              itemBuilder: (context) => const <PopupMenuEntry<_RoutineAction>>[
                PopupMenuItem<_RoutineAction>(
                  value: _RoutineAction.edit,
                  child: Text('수정'),
                ),
                PopupMenuItem<_RoutineAction>(
                  value: _RoutineAction.delete,
                  child: Text('삭제'),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

String _levelLabel(String level) => switch (level) {
  'beginner' => '초급',
  'intermediate' => '중급',
  'advanced' => '고급',
  _ => level,
};
