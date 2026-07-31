import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

import '../../application/post_providers.dart';
import '../comment_sheet.dart';
import '../models/feed_post.dart';
import 'post_actions_sheet.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import '../../../profile/presentation/user_profile_page.dart';

/// 인스타/스레드형 피드 카드. 미디어(영상·사진)를 히어로로 두고
/// 그 아래 액션 → 운동 요약 → 캡션 순으로 쌓는다.
class FeedPostCard extends ConsumerStatefulWidget {
  const FeedPostCard({required this.post, super.key});

  final FeedPost post;

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  bool? _liked;
  bool? _saved;
  int? _likes;

  FeedPost get post => widget.post;
  bool get _isLiked => _liked ?? post.likedByMe;
  bool get _isSaved => _saved ?? post.savedByMe;
  int get _likeCount => _likes ?? post.likes;

  /// 서버 응답을 기다리지 않고 먼저 반영한 뒤, 실패하면 되돌린다.
  Future<void> _toggleLike() async {
    final id = post.postId;
    if (id == null) return;
    final next = !_isLiked;
    setState(() {
      _liked = next;
      _likes = _likeCount + (next ? 1 : -1);
    });
    final result = await ref.read(postRepositoryProvider).toggleLike(id);
    if (!mounted) return;
    result.when(
      ok: (_) {},
      err: (failure) {
        setState(() {
          _liked = !next;
          _likes = _likeCount + (next ? -1 : 1);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  Future<void> _toggleSave() async {
    final id = post.postId;
    if (id == null) return;
    final next = !_isSaved;
    setState(() => _saved = next);
    final result = await ref.read(postRepositoryProvider).toggleSave(id);
    if (!mounted) return;
    result.when(
      ok: (_) {},
      err: (failure) {
        setState(() => _saved = !next);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  Future<void> _share() async {
    await Clipboard.setData(ClipboardData(text: post.caption));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('내용을 복사했습니다.')));
  }

  void _openComments() {
    final id = post.postId;
    if (id == null) return;
    showCommentSheet(context, postId: id);
  }

  void _openMore() {
    final id = post.postId;
    final authorId = post.authorId;
    if (id == null || authorId == null) return;
    showPostActionsSheet(
      context,
      ref,
      postId: id,
      authorId: authorId,
      isMine: post.isMine,
    );
  }

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
          _Header(post: post, onMore: _openMore),
          _Media(
            media: post.media,
            location: post.location,
            isLive: post.author.isLive,
          ),
          const SizedBox(height: 4),
          _Actions(
            likes: _likeCount,
            comments: post.comments,
            liked: _isLiked,
            saved: _isSaved,
            onLike: _toggleLike,
            onComment: _openComments,
            onShare: _share,
            onSave: _toggleSave,
          ),
          _SummaryStrip(summary: post.summary),
          _Caption(post: post),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.post, required this.onMore});

  final FeedPost post;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final author = post.author;
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 12, 11),
      child: Row(
        children: <Widget>[
          // 작성자를 눌러 프로필로 들어갈 수 있어야 한다.
          InkWell(
            onTap: post.authorId == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UserProfilePage(userId: post.authorId!),
                    ),
                  ),
            borderRadius: BorderRadius.circular(22),
            child: _Avatar(name: author.name, ringed: author.isLive),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // 닉네임이 길어도 레벨 칩을 밀어내지 않도록 줄인다.
                    Flexible(
                      child: Text(
                        author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: t.text,
                        ),
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
          // 팔로우와 더보기는 서로 배타적이지 않다. 내 글이 아니면 팔로우도 보여준다.
          if (!post.isMine && post.authorId != null)
            FollowButton(userId: post.authorId!, compact: true),
          IconButton(
            tooltip: '더보기',
            onPressed: onMore,
            icon: Icon(Icons.more_horiz_rounded, color: t.faintText, size: 22),
          ),
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
        initialOf(name),
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
            child: (media.url?.isNotEmpty ?? false) && !isVideo
                ? Image.network(
                    media.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _MediaFallback(),
                  )
                : isVideo
                ? null
                : const _MediaFallback(),
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

/// 이미지가 없거나 불러오지 못했을 때의 자리 표시다.
class _MediaFallback extends StatelessWidget {
  const _MediaFallback();

  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      Icons.photo_camera_outlined,
      size: 34,
      color: Colors.black.withValues(alpha: 0.16),
    ),
  );
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
  const _Actions({
    required this.likes,
    required this.comments,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
  });

  final int likes;
  final int comments;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
      child: Row(
        children: <Widget>[
          _ActionItem(
            icon: liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: formatCompactNumber(likes),
            color: liked ? t.like : t.text,
            semanticLabel: liked ? '좋아요 취소' : '좋아요',
            onTap: onLike,
          ),
          _ActionItem(
            icon: Icons.mode_comment_outlined,
            label: formatCompactNumber(comments),
            color: t.text,
            semanticLabel: '댓글 ${formatInt(comments)}개',
            onTap: onComment,
          ),
          _ActionItem(
            icon: Icons.send_outlined,
            color: t.text,
            semanticLabel: '공유',
            onTap: onShare,
          ),
          const Spacer(),
          _ActionItem(
            icon: saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: t.text,
            semanticLabel: saved ? '저장 취소' : '저장',
            onTap: onSave,
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
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 23, color: color),
              if (label != null) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            Flexible(child: _Metric(metric: summary.metrics[i])),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: t.faintText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: t.warning,
              ),
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
