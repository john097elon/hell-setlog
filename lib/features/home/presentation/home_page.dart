import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/domain/entities/routine.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';
import 'package:heal_setlog/features/routine/application/routine_providers.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';
import 'package:heal_setlog/features/workout_log/application/workout_providers.dart';

/// 오늘의 운동과 이번 주 기록을 요약하는 개인 대시보드다.
class HomePage extends ConsumerWidget {
  /// 홈 화면을 생성한다.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyVolume = ref.watch(weeklyVolumeProvider());
    final activeSession = ref.watch(activeSessionProvider);
    final routines = ref.watch(routinesProvider);
    final copy = context.l10n;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Text(
              copy.todayWorkout,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${now.month}.${now.day} · ${copy.statsThisWeek}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            weeklyVolume.when(
              loading: () => const _SummaryLoading(),
              error: (_, _) => _LoadError(message: copy.statsLoadError),
              data: (result) => result.when(
                ok: (volumes) => _WeeklySummary(volumes: volumes),
                err: (failure) => _LoadError(message: failure.message),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            activeSession.when(
              loading: () => const SizedBox(
                height: 48,
                child: Center(child: Icon(Icons.hourglass_top_rounded)),
              ),
              error: (_, _) =>
                  _WorkoutCta(onPressed: () => context.go('/workout')),
              data: (result) => result.when(
                ok: (session) => _WorkoutCta(
                  session: session,
                  onPressed: () => context.go('/workout'),
                ),
                err: (_) =>
                    _WorkoutCta(onPressed: () => context.go('/workout')),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              copy.routines,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              copy.routinesDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            routines.when(
              loading: () => const _RoutineLoading(),
              error: (_, _) => _LoadError(message: copy.statsLoadError),
              data: (result) => result.when(
                ok: (items) => _RoutineSection(
                  routines: items,
                  onOpen: () => context.push('/routines'),
                ),
                err: (failure) => _LoadError(message: failure.message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({required this.volumes});

  final Map<DateTime, double> volumes;

  @override
  Widget build(BuildContext context) {
    final totalVolume = volumes.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final workoutDays = volumes.values.where((value) => value > 0).length;
    final copy = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              copy.statsThisWeek,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              copy.statsVolumeValue(totalVolume.toStringAsFixed(0)),
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontFeatures: kTabularFigures),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              copy.statsWorkoutDaysValue(workoutDays),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontFeatures: kTabularFigures),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCta extends StatelessWidget {
  const _WorkoutCta({required this.onPressed, this.session});

  final VoidCallback onPressed;
  final WorkoutSession? session;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final isActive = session?.isActive ?? false;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isActive ? Icons.play_circle_fill_rounded : Icons.play_arrow_rounded,
        ),
        label: Text(isActive ? copy.workoutInProgress : copy.startWorkout),
      ),
    );
  }
}

class _RoutineSection extends StatelessWidget {
  const _RoutineSection({required this.routines, required this.onOpen});

  final List<Routine> routines;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(context.l10n.routinesDescription),
        ),
      );
    }
    final visibleRoutines = routines.take(3).toList(growable: false);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleRoutines.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Card(
          child: ListTile(
            title: Text(visibleRoutines[index].name),
            subtitle: visibleRoutines[index].description == null
                ? null
                : Text(visibleRoutines[index].description!),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpen,
          ),
        ),
      ),
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) => const Card(
    child: SizedBox(
      height: 152,
      child: Center(child: Icon(Icons.hourglass_top_rounded)),
    ),
  );
}

class _RoutineLoading extends StatelessWidget {
  const _RoutineLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Icon(Icons.hourglass_top_rounded));
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
  );
}
