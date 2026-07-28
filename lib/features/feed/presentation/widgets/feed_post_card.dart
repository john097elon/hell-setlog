import 'package:flutter/material.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

import '../models/feed_post.dart';

/// 인스타/스레드형 피드 카드. 미디어(영상·사진)를 히어로로 두고
/// 그 아래 액션 → 운동 요약 → 캡션 순으로 쌓는다.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({required this.post, super.key});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.border.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(post: post),
          _Media(
            media: post.media,
            location: post.location,
            isLive: post.author.isLive,
          ),
          const SizedBox(height: 4),
          _Actions(likes: post.likes, comments: post.comments),
          _SummaryStrip(summary: post.summary),
          _Caption(post: post),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final author = post.author;
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 12, 11),
      child: Row(
        children: <Widget>[
          _Avatar(name: author.name, ringed: author.isLive),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      author.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _LevelBadge(level: author.level),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${post.timeLabel} · ${post.bodyPart}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: t.faintText,
                  ),
                ),
              ],
            ),
          ),
          if (post.showFollow)
            Text(
              '팔로우',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: t.brand,
              ),
            )
          else
            Icon(Icons.more_horiz_rounded, color: t.faintText, size: 22),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.ringed = false});

  final String name;
  final bool ringed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 이모지 대신 이름 첫 글자 모노그램(실제 앱 톤).
    final inner = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: ringed ? t.card : t.border,
          width: ringed ? 2 : 1,
        ),
      ),
      child: Text(
        name.characters.first,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: t.text,
          letterSpacing: -0.3,
        ),
      ),
    );
    if (!ringed) return inner;
    // 라이브만 얇은 액센트 링(그라디언트 남발 대신 절제).
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: t.like, width: 1.5),
      ),
      child: inner,
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 애플 모노크롬: 레벨은 뉴트럴 그레이 칩.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.border),
      ),
      child: Text(
        'LV.$level',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: t.mutedText,
        ),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.media, this.location, this.isLive = false});

  final FeedMedia media;
  final String? location;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final isVideo = media.kind == FeedMediaKind.video;
    return AspectRatio(
      aspectRatio: isVideo ? 9 / 12 : 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: media.gradient,
              ),
            ),
            // 사진 자리: 큰 이모지 대신 절제된 아웃라인 글리프.
            child: isVideo
                ? null
                : Center(
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 34,
                      color: Colors.black.withValues(alpha: 0.16),
                    ),
                  ),
          ),
          if (isVideo) const Center(child: _PlayButton()),
          if (isLive)
            Positioned(
              top: 12,
              left: 12,
              child: _Pill(
                text: 'LIVE',
                bg: context.tokens.like,
                fg: Colors.white,
                icon: Icons.fiber_manual_record,
              ),
            )
          else if (location != null)
            Positioned(
              top: 12,
              left: 12,
              child: _Pill(
                text: location!,
                bg: Colors.white.withValues(alpha: 0.82),
                fg: context.tokens.text,
                icon: Icons.place_outlined,
              ),
            ),
          if (isVideo && media.durationLabel != null)
            Positioned(
              top: 12,
              right: 12,
              child: _Pill(
                text: media.durationLabel!,
                bg: Colors.black.withValues(alpha: 0.4),
                fg: Colors.white,
              ),
            ),
          if (media.count > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: _Pill(
                text: '1/${media.count}',
                bg: Colors.black.withValues(alpha: 0.4),
                fg: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.28),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      boxShadow: <BoxShadow>[
        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16),
      ],
    ),
    child: const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(
            icon,
            size: icon == Icons.fiber_manual_record ? 8 : 12,
            color: fg,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.likes, required this.comments});

  final int likes;
  final int comments;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      child: Row(
        children: <Widget>[
          _ActionItem(
            icon: Icons.favorite_rounded,
            label: formatInt(likes),
            color: t.like,
            semanticLabel: '좋아요 ${formatInt(likes)}개',
          ),
          _ActionItem(
            icon: Icons.mode_comment_outlined,
            label: formatInt(comments),
            color: t.text,
            semanticLabel: '댓글 ${formatInt(comments)}개',
          ),
          _ActionItem(
            icon: Icons.send_outlined,
            color: t.text,
            semanticLabel: '공유',
          ),
          const Spacer(),
          _ActionItem(
            icon: Icons.bookmark_border_rounded,
            color: t.text,
            semanticLabel: '저장',
          ),
        ],
      ),
    );
  }
}

/// 최소 44dp 터치 타겟 + 탭 피드백(잉크)을 갖춘 피드 액션.
class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.color,
    required this.semanticLabel,
    this.label,
  });

  final IconData icon;
  final Color color;
  final String semanticLabel;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 23, color: color),
              if (label != null) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          for (var i = 0; i < summary.metrics.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                width: 0.5,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: t.borderStrong.withValues(alpha: 0.4),
              ),
            _Metric(metric: summary.metrics[i]),
          ],
          const Spacer(),
          if (summary.prLabel != null)
            _PrTag(label: summary.prLabel!)
          else if (summary.xp != null)
            Text(
              '+${summary.xp} XP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: t.success,
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.metric});

  final ({String label, String value}) metric;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          metric.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: t.faintText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            color: t.text,
          ),
        ),
      ],
    );
  }
}

class _PrTag extends StatelessWidget {
  const _PrTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: t.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: t.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.workspace_premium_rounded, size: 13, color: t.warning),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: t.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '${post.author.name} ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                TextSpan(
                  text: post.caption,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: t.text.withValues(alpha: 0.82),
                  ),
                ),
                if (post.summary.prLabel != null && post.summary.xp != null)
                  TextSpan(
                    text: '  +${post.summary.xp} XP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: t.success,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '댓글 ${post.comments}개 모두 보기',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: t.faintText,
            ),
          ),
        ],
      ),
    );
  }
}
