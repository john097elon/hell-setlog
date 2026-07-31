import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_list.dart';

/// 큰 제목이 스크롤에 따라 접히는 화면 뼈대.
///
/// iOS 기본 앱들의 큰 제목처럼, 처음에는 제목이 크게 보이고 내려가면
/// 상단 바로 접힌다. 주요 탭 화면은 이걸 쓴다.
class AppScreen extends StatelessWidget {
  const AppScreen({
    required this.title,
    required this.slivers,
    this.actions = const <Widget>[],
    this.onRefresh,
    super.key,
  });

  final String title;

  /// 본문. 목록이면 SliverList, 카드 묶음이면 SliverToBoxAdapter를 넘긴다.
  final List<Widget> slivers;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scroll = CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          backgroundColor: t.bg,
          surfaceTintColor: Colors.transparent,
          title: Text(title),
          actions: actions,
        ),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
    return Scaffold(
      backgroundColor: t.bg,
      body: onRefresh == null
          ? scroll
          : RefreshIndicator(onRefresh: onRefresh!, child: scroll),
    );
  }
}

/// 좌우 여백을 화면 전체에서 통일한다.
class AppPagePadding extends StatelessWidget {
  const AppPagePadding({required this.child, this.top = 0, super.key});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, top, AppSpacing.lg, 0),
    child: child,
  );
}

/// 지표 한 칸. 숫자를 먼저 읽게 하고 라벨은 아래 작게 둔다.
class AppMetric extends StatelessWidget {
  const AppMetric({
    required this.label,
    required this.value,
    this.size = 22,
    super.key,
  });

  final String label;
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.metric(context, size: size),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.metricLabel(context),
      ),
    ],
  );
}

/// 지표 여러 칸을 한 줄로. 사이에 얇은 세로선을 둔다.
class AppMetricRow extends StatelessWidget {
  const AppMetricRow({required this.metrics, super.key});

  final List<AppMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < metrics.length; index++) ...<Widget>[
            if (index > 0)
              Container(
                width: 0.5,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: t.border,
              ),
            Expanded(child: metrics[index]),
          ],
        ],
      ),
    );
  }
}
