import 'package:flutter/material.dart';

import '../../../../core/constants/workout.dart';
import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_list.dart';
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
    final time =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return AppSection(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: <Widget>[
        AppRow(
          title: context.l10n.rest,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(time, style: AppText.metric(context, size: 20)),
              IconButton(
                tooltip: context.l10n.addSeconds(kRestTimerIncrementSeconds),
                onPressed: onAdd,
                icon: const Icon(Icons.more_time_rounded),
              ),
              IconButton(
                tooltip: context.l10n.skip,
                onPressed: onSkip,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
