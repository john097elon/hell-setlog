import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// P2 통계 구현 전의 레거시 UI 검토용 화면이다.
class StatsPage extends StatelessWidget {
  /// 통계 목업 화면을 생성한다.
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(copy.statsTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    copy.statsLater,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(copy.statsDescription, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(copy.statsLaterDescription, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
