import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/features/stats/presentation/stats_page.dart';
import 'package:heal_setlog/features/workout_log/presentation/workout_page.dart';

/// 세트로그, 통계, 몬스터 하위 화면의 상태를 보존하는 운동 탭이다.
class WorkoutTabPage extends StatefulWidget {
  const WorkoutTabPage({super.key});

  @override
  State<WorkoutTabPage> createState() => _WorkoutTabPageState();
}

class _WorkoutTabPageState extends State<WorkoutTabPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.workout),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text(copy.setLogs)),
                ButtonSegment<int>(value: 1, label: Text(copy.stats)),
                ButtonSegment<int>(value: 2, label: Text(copy.monster)),
              ],
              selected: <int>{_selectedIndex},
              showSelectedIcon: false,
              onSelectionChanged: (selected) =>
                  setState(() => _selectedIndex = selected.first),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const <Widget>[
          WorkoutPage(embedded: true),
          StatsPage(embedded: true),
          _MonsterPlaceholder(),
        ],
      ),
    );
  }
}

class _MonsterPlaceholder extends StatelessWidget {
  const _MonsterPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.pets_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.monsterComingSoon,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.monsterComingSoonDescription,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
