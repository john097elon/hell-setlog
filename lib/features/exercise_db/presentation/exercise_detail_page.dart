import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/exercise_guide.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            ExerciseThumbnail(
              equipment: exercise.equipment,
              thumbnailUrl: exercise.thumbnailUrl,
              size: 96,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    exercise.nameKo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
        const SizedBox(height: 28),
        if (item == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
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
              spacing: 8,
              runSpacing: 8,
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          leading,
          const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
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
