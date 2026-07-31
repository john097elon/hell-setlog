import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_format.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/entities/post.dart';
import '../../../settings/application/settings_controller.dart';

/// 프로필 게시물 그리드. 내 프로필과 다른 사용자 프로필이 함께 쓴다.
class PostGridSliver extends ConsumerWidget {
  const PostGridSliver({required this.posts, required this.onTap, super.key});

  final List<Post> posts;
  final void Function(Post post) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightUnit = ref.watch(
      settingsControllerProvider.select((state) => state.weightUnit),
    );
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => PostThumbnail(
            post: posts[index],
            weightUnit: weightUnit,
            onTap: () => onTap(posts[index]),
          ),
          childCount: posts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
      ),
    );
  }
}

/// 그리드 한 칸. 사진은 이미지로, 영상과 기록 전용 글은 대체 표시로 보여준다.
class PostThumbnail extends StatelessWidget {
  const PostThumbnail({
    required this.post,
    required this.onTap,
    this.weightUnit = WeightUnit.kg,
    super.key,
  });

  final Post post;
  final VoidCallback onTap;
  final WeightUnit weightUnit;

  bool get _isVideo => post.mediaKind == PostMediaKind.video;
  bool get _hasMedia => post.mediaUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: '게시물 열기',
      child: InkWell(
        key: Key('post-thumb-${post.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.bg,
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (_hasMedia && !_isVideo)
                  Image.network(
                    post.mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallback(t),
                  )
                else
                  _fallback(t),
                if (_isVideo)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 18,
                        color: t.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                // 어떤 글에 반응이 붙었는지 목록에서 바로 보이게 한다.
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _Reactions(
                    likes: post.likeCount,
                    comments: post.commentCount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 미디어를 못 그릴 때도 무엇을 올린 글인지 알 수 있게 요약을 보여준다.
  Widget _fallback(AppTokens t) => Padding(
    padding: const EdgeInsets.all(6),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          _isVideo ? Icons.videocam_outlined : Icons.article_outlined,
          size: 20,
          color: t.faintText,
        ),
        const SizedBox(height: 4),
        Text(
          post.volumeKg != null
              ? formatWeightWithUnit(post.volumeKg!, unit: weightUnit)
              : (post.caption.isEmpty ? '기록' : post.caption),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: t.mutedText,
          ),
        ),
      ],
    ),
  );
}

/// 썸네일 위 반응 배지. 좋아요와 댓글이 모두 0이면 숨긴다.
class _Reactions extends StatelessWidget {
  const _Reactions({required this.likes, required this.comments});

  final int likes;
  final int comments;

  @override
  Widget build(BuildContext context) {
    if (likes == 0 && comments == 0) return const SizedBox.shrink();
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: t.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.favorite_rounded, size: 11, color: t.like),
          const SizedBox(width: 3),
          _count(t, likes),
          const SizedBox(width: 6),
          Icon(Icons.mode_comment_rounded, size: 10, color: t.mutedText),
          const SizedBox(width: 3),
          _count(t, comments),
        ],
      ),
    );
  }

  Widget _count(AppTokens t, int value) => Text(
    formatCompactNumber(value),
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: t.text,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    ),
  );
}
