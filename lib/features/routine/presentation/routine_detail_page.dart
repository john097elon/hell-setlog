import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/routine.dart';
import '../../../domain/entities/routine_item.dart';
import '../../exercise_db/application/exercise_providers.dart';
import '../../exercise_db/presentation/widgets/exercise_thumbnail.dart';
import '../application/routine_providers.dart';
import '../application/start_from_routine_controller.dart';

class RoutineDetailPage extends ConsumerWidget {
  const RoutineDetailPage({required this.routineId, super.key});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);
    final items = ref.watch(routineItemsProvider(routineId));
    final routine = routines.valueOrNull?.when(
      ok: (values) =>
          values.where((value) => value.id == routineId).firstOrNull,
      err: (_) => null,
    );
    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: AppBar(),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
        data: (result) => result.when(
          ok: (values) => _RoutineDetailBody(
            routine: routine,
            items: values..sort((a, b) => a.order.compareTo(b.order)),
            onStart: () => _start(context, ref),
            onEdit: () => context.push('/routines/edit/$routineId'),
          ),
          err: (failure) => Center(child: Text(failure.message)),
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(startFromRoutineControllerProvider)
        .start(routineId);
    if (!context.mounted) return;
    result.when(
      ok: (_) => context.go('/workout'),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }
}

class _RoutineDetailBody extends ConsumerWidget {
  const _RoutineDetailBody({
    required this.routine,
    required this.items,
    required this.onStart,
    required this.onEdit,
  });

  final Routine? routine;
  final List<RoutineItem> items;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final firstExercise = items.isEmpty
        ? null
        : ref
              .watch(exerciseByIdProvider(items.first.exerciseId))
              .valueOrNull
              ?.when(ok: (value) => value, err: (_) => null);
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              itemCount: items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _Header(
                    name: routine?.name ?? '내 운동',
                    muscleGroup: firstExercise?.muscleGroup,
                  );
                }
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xl,
                      bottom: AppSpacing.sm,
                    ),
                    child: items.isEmpty
                        ? Text(
                            '아직 담은 운동이 없어요. 수정에서 운동을 넣어 주세요.',
                            style: TextStyle(color: t.mutedText),
                          )
                        : Text(
                            '운동 ${items.length}개',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(color: t.text),
                          ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _RoutineExerciseTile(item: items[index - 2]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('start-routine'),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('시작'),
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('수정')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.muscleGroup});

  final String name;
  final MuscleGroup? muscleGroup;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: t.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MuscleChip(muscleGroup: muscleGroup),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: t.border),
          ),
          child: Icon(Icons.accessibility_new_rounded, color: t.mutedText),
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.muscleGroup});

  final MuscleGroup? muscleGroup;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: t.border),
      ),
      child: Text(
        _muscleGroupLabel(muscleGroup),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: t.mutedText),
      ),
    );
  }
}

class _RoutineExerciseTile extends ConsumerWidget {
  const _RoutineExerciseTile({required this.item});

  final RoutineItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseByIdProvider(item.exerciseId));
    return exercise.when(
      loading: () => const SizedBox(height: 72),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) => result.when(
        ok: (value) => AppSection(
          margin: EdgeInsets.zero,
          children: <Widget>[
            AppRow(
              title: value.nameKo,
              subtitle: equipmentLabelKo(value.equipment),
              leading: ExerciseThumbnail(
                equipment: value.equipment,
                thumbnailUrl: value.thumbnailUrl,
                size: AppSpacing.xxl,
              ),
              value: '${item.targetSets}세트 x ${item.targetReps}회',
            ),
          ],
        ),
        err: (_) => const SizedBox.shrink(),
      ),
    );
  }
}

String _muscleGroupLabel(MuscleGroup? group) => switch (group) {
  MuscleGroup.chest => '가슴',
  MuscleGroup.back => '등',
  MuscleGroup.shoulders => '어깨',
  MuscleGroup.legs => '하체',
  MuscleGroup.arms => '팔',
  MuscleGroup.core => '코어',
  MuscleGroup.fullBody => '전신',
  MuscleGroup.other || null => '내 운동',
};
