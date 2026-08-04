import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/exercise_guide.dart';
import '../../../domain/entities/personal_record.dart';
import '../../stats/application/stats_providers.dart';
import '../application/exercise_guide_provider.dart';
import '../application/exercise_providers.dart';
import 'widgets/exercise_thumbnail.dart';

class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));
    final guides = ref.watch(exerciseGuideProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('종목 상세')),
      body: exercise.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Message('종목 정보를 불러오지 못했습니다'),
        data: (result) => result.when(
          ok: (item) => guides.when(
            loading: () => _DetailBody(exercise: item),
            error: (_, _) => _DetailBody(exercise: item),
            data: (items) =>
                _DetailBody(exercise: item, guide: items[exerciseId]),
          ),
          err: (_) => const _Message('종목 정보를 불러오지 못했습니다'),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.exercise, this.guide});

  final Exercise exercise;
  final ExerciseGuide? guide;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final item = guide;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            ExerciseThumbnail(
              equipment: exercise.equipment,
              thumbnailUrl: exercise.thumbnailUrl,
              size: AppSpacing.xxl * 3,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    exercise.nameKo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      _Chip(label: equipmentLabelKo(exercise.equipment)),
                      _Chip(label: _muscleGroupLabel(exercise.muscleGroup)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _PersonalRecords(exerciseId: exercise.id),
        if (item == null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: t.border),
            ),
            child: const Text('가이드 준비 중입니다'),
          )
        else ...<Widget>[
          _Section(title: '요약', child: Text(item.summary)),
          _Section(
            title: '수행 순서',
            child: Column(
              children: <Widget>[
                for (var index = 0; index < item.steps.length; index++)
                  _Line(icon: '${index + 1}', text: item.steps[index]),
              ],
            ),
          ),
          _Section(
            title: '팁',
            child: Column(
              children: <Widget>[
                for (final tip in item.tips)
                  _Line(icon: Icons.check_circle_outline, text: tip),
              ],
            ),
          ),
          _Section(
            title: '흔한 실수',
            child: Column(
              children: <Widget>[
                for (final mistake in item.mistakes)
                  _Line(icon: Icons.warning_amber_outlined, text: mistake),
              ],
            ),
          ),
          _Section(
            title: '주동근',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final muscle in item.primaryMuscles) _Chip(label: muscle),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PersonalRecords extends ConsumerWidget {
  const _PersonalRecords({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(personalRecordsProvider(exerciseId))
      .when(
        loading: () => AppSection(
          title: context.l10n.personalRecordsTitle,
          children: const <Widget>[
            SizedBox(
              height: AppSpacing.xl * 2,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (_, _) =>
            _messageSection(context, context.l10n.personalRecordsLoadError),
        data: (result) => result.when(
          ok: (records) => AppSection(
            title: context.l10n.personalRecordsTitle,
            children: records.isEmpty
                ? <Widget>[AppRow(title: context.l10n.personalRecordsEmpty)]
                : <Widget>[
                    for (final record in records)
                      AppRow(
                        title: prTypeLabel(record.type),
                        value: _recordValue(record),
                      ),
                  ],
          ),
          err: (_) =>
              _messageSection(context, context.l10n.personalRecordsLoadError),
        ),
      );

  AppSection _messageSection(BuildContext context, String message) =>
      AppSection(
        title: context.l10n.personalRecordsTitle,
        children: <Widget>[AppRow(title: message)],
      );
}

String _recordValue(PersonalRecord record) => switch (record.type) {
  PrType.oneRm => formatWeightWithUnit(record.value),
  PrType.volume => formatCompactWeight(record.value),
  PrType.reps => '${formatInt(record.value)}회',
  PrType.distance => formatDistance(record.value),
  PrType.duration => formatDuration(record.value.round()),
  PrType.speed => formatPace(record.value),
};

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final Object icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final leading = icon is IconData
        ? Icon(icon as IconData, size: 20, color: t.success)
        : SizedBox(
            width: 20,
            child: Text(icon as String, style: TextStyle(color: t.mutedText)),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: t.border),
      ),
      child: Text(label, style: TextStyle(color: t.mutedText)),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

String _muscleGroupLabel(MuscleGroup value) => switch (value) {
  MuscleGroup.chest => '가슴',
  MuscleGroup.back => '등',
  MuscleGroup.shoulders => '어깨',
  MuscleGroup.legs => '하체',
  MuscleGroup.arms => '팔',
  MuscleGroup.core => '코어',
  MuscleGroup.fullBody => '전신',
  MuscleGroup.other => '기타',
};
