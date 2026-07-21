import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// 오늘의 운동과 파티 활동을 요약하는 목업 홈 화면이다.
class HomePage extends StatelessWidget {
  /// 홈 화면을 생성한다.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(copy.todayWorkout)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    copy.todayWorkout,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(copy.todayWorkoutDescription),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/workout'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(copy.startWorkout),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(label: copy.streak, value: copy.streakValue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: copy.weekWorkout,
                  value: copy.weekWorkoutValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.groups_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(copy.partyActivity),
              subtitle: Text(copy.partyActivityMessage),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/party'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
