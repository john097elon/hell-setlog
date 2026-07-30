import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// 로딩 상태. blank(SizedBox.shrink) 대신 화면 전역에서 이걸 쓴다.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: CircularProgressIndicator(strokeWidth: 2.5),
    ),
  );
}

/// 데이터 없음/에러 빈 상태. 아이콘 + 제목 + 설명 + 선택 액션.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: t.faintText),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 한 덩어리 자리표시자. 로딩 중 레이아웃이 튀지 않도록 실제 크기를 미리 차지한다.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    required this.height,
    this.width,
    this.radius = 8,
    super.key,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 동작 줄이기가 켜져 있으면 깜빡임 없이 고정 톤으로 둔다.
    if (MediaQuery.disableAnimationsOf(context)) {
      return _box(t.border);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          _box(Color.lerp(t.border, t.bg, _controller.value) ?? t.border),
    );
  }

  Widget _box(Color color) => Container(
    width: widget.width,
    height: widget.height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(widget.radius),
    ),
  );
}

/// 피드 카드 모양 자리표시자. 목록 로딩 중 화면이 비지 않게 한다.
class FeedCardSkeleton extends StatelessWidget {
  const FeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.border.withValues(alpha: 0.6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppSkeleton(height: 38, width: 38, radius: 19),
              SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeleton(height: 13, width: 96),
                  SizedBox(height: 6),
                  AppSkeleton(height: 11, width: 64),
                ],
              ),
            ],
          ),
          SizedBox(height: 14),
          AppSkeleton(height: 200, radius: 14),
          SizedBox(height: 14),
          AppSkeleton(height: 12, width: 180),
          SizedBox(height: 8),
          AppSkeleton(height: 12, width: 120),
        ],
      ),
    );
  }
}

/// 피드 목록 자리표시자.
class FeedListSkeleton extends StatelessWidget {
  const FeedListSkeleton({this.count = 2, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(top: 8, bottom: 24),
    itemCount: count,
    itemBuilder: (context, _) => const FeedCardSkeleton(),
  );
}
