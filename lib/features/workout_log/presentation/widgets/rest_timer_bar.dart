import 'package:flutter/material.dart';

import '../../../../core/constants/workout.dart';
import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/rest_timer_controller.dart';

/// 휴식 타이머 카드. 실행 중일 때만 표시하며 큰 tabular 시간으로 강조한다.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({
    required this.state,
    required this.onAdd,
    required this.onSkip,
    super.key,
  });

  final RestTimerState state;
  final VoidCallback onAdd;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    if (!state.isRunning) return const SizedBox.shrink();
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.l10n.rest,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.primary,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onAdd,
            child: Text(context.l10n.addSeconds(kRestTimerIncrementSeconds)),
          ),
          TextButton(onPressed: onSkip, child: Text(context.l10n.skip)),
        ],
      ),
    );
  }
}
