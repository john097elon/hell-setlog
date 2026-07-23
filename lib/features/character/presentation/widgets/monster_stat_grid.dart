import 'package:flutter/material.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/features/character/presentation/models/monster_view_data.dart';

/// 몬스터의 부위별 목업 스탯을 카드 그리드로 표시한다.
class MonsterStatGrid extends StatelessWidget {
  const MonsterStatGrid({
    required this.stats,
    required this.labelFor,
    super.key,
  });

  final List<MonsterStatViewData> stats;
  final String Function(MonsterStatKind kind) labelFor;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.55,
    ),
    itemCount: stats.length,
    itemBuilder: (BuildContext context, int index) => _MonsterStatCard(
      stat: stats[index],
      label: labelFor(stats[index].kind),
    ),
  );
}

class _MonsterStatCard extends StatelessWidget {
  const _MonsterStatCard({required this.stat, required this.label});

  final MonsterStatViewData stat;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.labelLarge),
            const Spacer(),
            Text(
              formatInt(stat.value),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFeatures: kTabularFigures,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: stat.progress,
              minHeight: 6,
              color: context.tokens.brand,
              backgroundColor: context.tokens.surface,
            ),
          ],
        ),
      ),
    );
  }
}
