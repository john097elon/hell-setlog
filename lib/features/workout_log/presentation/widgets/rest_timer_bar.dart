import 'package:flutter/material.dart';

import '../../../../core/constants/workout.dart';
import '../../../../core/extensions/build_context_x.dart';
import '../../application/rest_timer_controller.dart';

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
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          const Icon(Icons.timer_outlined),
          const SizedBox(width: 10),
          Text(
            '${context.l10n.rest} ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.titleMedium,
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
