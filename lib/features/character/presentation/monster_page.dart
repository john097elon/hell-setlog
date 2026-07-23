import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/features/character/presentation/models/monster_view_data.dart';
import 'package:heal_setlog/features/character/presentation/widgets/monster_stat_grid.dart';

/// P6 실데이터 연동 전 몬스터 성장을 보여 주는 프레젠테이션 목업 화면이다.
class MonsterPage extends StatelessWidget {
  const MonsterPage({this.data = monsterMockViewData, super.key});

  final MonsterViewData data;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(copy.monsterMockName, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${copy.level} ${data.level} · ${_bodyTypeLabel(context, data.bodyType)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Image.asset(
                data.stageAssetPath,
                width: 192,
                height: 192,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(copy.monsterExperience, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: LinearProgressIndicator(
                value: data.experienceProgress,
                minHeight: 10,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 12),
            Text('${data.experience} / ${data.experienceMaximum}'),
          ],
        ),
        const SizedBox(height: 28),
        MonsterStatGrid(
          stats: data.stats,
          labelFor: (MonsterStatKind kind) => _statLabel(context, kind),
        ),
      ],
    );
  }

  String _bodyTypeLabel(BuildContext context, MonsterBodyType bodyType) =>
      switch (bodyType) {
        MonsterBodyType.upper => context.l10n.monsterBodyTypeUpper,
        MonsterBodyType.lower => context.l10n.monsterBodyTypeLower,
        MonsterBodyType.balanced => context.l10n.monsterBodyTypeBalanced,
      };

  String _statLabel(BuildContext context, MonsterStatKind kind) {
    final copy = context.l10n;
    return switch (kind) {
      MonsterStatKind.arm => copy.monsterStatArm,
      MonsterStatKind.leg => copy.monsterStatLeg,
      MonsterStatKind.core => copy.monsterStatCore,
      MonsterStatKind.endure => copy.monsterStatEndure,
    };
  }
}
