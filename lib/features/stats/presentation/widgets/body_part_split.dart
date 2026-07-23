import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';

/// 근육군별 운동 볼륨 비중을 가로 막대로 보여준다.
class BodyPartSplit extends StatelessWidget {
  const BodyPartSplit({required this.volumes, super.key});

  final Map<MuscleGroup, double> volumes;

  @override
  Widget build(BuildContext context) {
    final total = volumes.values.fold<double>(0, (sum, value) => sum + value);
    final entries = volumes.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _BodyPartBar(
                label: _label(context, entry.key),
                percent: total == 0 ? 0 : entry.value / total,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _label(BuildContext context, MuscleGroup group) {
    final copy = context.l10n;
    return switch (group) {
      MuscleGroup.chest => copy.muscleChest,
      MuscleGroup.back => copy.muscleBack,
      MuscleGroup.shoulders => copy.muscleShoulders,
      MuscleGroup.legs => copy.muscleLegs,
      MuscleGroup.arms => copy.muscleArms,
      MuscleGroup.core => copy.muscleCore,
      MuscleGroup.fullBody => copy.muscleFullBody,
      MuscleGroup.other => copy.muscleOther,
    };
  }
}

class _BodyPartBar extends StatelessWidget {
  const _BodyPartBar({required this.label, required this.percent});

  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '${formatInt(percent * 100)}%',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontFeatures: kTabularFigures),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
        child: LinearProgressIndicator(
          value: percent,
          minHeight: 8,
          color: AppColors.brand,
          backgroundColor: AppColors.mutedSurface,
        ),
      ),
    ],
  );
}
