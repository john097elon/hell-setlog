import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/post_comment.dart';
import '../../../domain/entities/post_reaction.dart';
import '../../profile/application/profile_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../application/post_providers.dart';
import 'video_player_page.dart';

/// 게시물 하나를 열어 반응(좋아요)과 댓글을 함께 본다.
class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({required this.post, super.key});

  final Post post;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  String get _postId => widget.post.id;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await ref
        .read(postRepositoryProvider)
        .addComment(_postId, body);
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      ok: (_) {
        _controller.clear();
        // 작성자 이름이 채워진 목록을 다시 읽는다.
        ref.invalidate(postCommentsProvider(_postId));
        ref.invalidate(myPostsProvider);
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final likers = ref.watch(postLikersProvider(_postId));
    final comments = ref.watch(postCommentsProvider(_postId));
    final weightUnit = ref.watch(
      settingsControllerProvider.select((state) => state.weightUnit),
    );
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(title: const Text('게시물')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(postLikersProvider(_postId))
            ..invalidate(postCommentsProvider(_postId));
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            _PostSummary(post: widget.post, weightUnit: weightUnit),
            _SectionHeader(
              title: '좋아요',
              count: likers.valueOrNull?.length ?? widget.post.likeCount,
            ),
            likers.when(
              loading: () => const _SectionLoading(),
              error: (_, _) => const _SectionMessage('반응을 불러오지 못했습니다'),
              data: (items) => items.isEmpty
                  ? const _SectionMessage('아직 반응이 없습니다')
                  : Column(
                      children: <Widget>[
                        for (final liker in items) _LikerTile(liker: liker),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            _SectionHeader(
              title: '댓글',
              count: comments.valueOrNull?.length ?? widget.post.commentCount,
            ),
            comments.when(
              loading: () => const _SectionLoading(),
              error: (_, _) => const _SectionMessage('댓글을 불러오지 못했습니다'),
              data: (items) => items.isEmpty
                  ? const _SectionMessage('첫 댓글을 남겨보세요')
                  : Column(
                      children: <Widget>[
                        for (final comment in items)
                          _CommentTile(comment: comment),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            8 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('post-detail-comment-input'),
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: '댓글 입력'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '전송',
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 글 자체(미디어·운동 요약·캡션).
class _PostSummary extends StatelessWidget {
  const _PostSummary({required this.post, required this.weightUnit});

  final Post post;
  final WeightUnit weightUnit;

  bool get _isVideo => post.mediaKind == PostMediaKind.video;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final metrics = <String>[
      if (post.volumeKg != null)
        formatWeightWithUnit(post.volumeKg!, unit: weightUnit),
      if (post.durationMin != null) '${post.durationMin}분',
      if (post.prLabel != null) post.prLabel!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 미디어가 화면을 다 먹으면 반응·댓글이 접혀 보이지 않는다.
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.38).clamp(
            180.0,
            380.0,
          ),
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(color: t.surface),
            child: post.mediaUrl.isNotEmpty
                ? _isVideo
                      ? Semantics(
                          button: true,
                          label: context.l10n.videoPlay,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => VideoPlayerPage(
                                  mediaUrl: post.mediaUrl,
                                  isVideo: true,
                                ),
                              ),
                            ),
                            child: _placeholder(t),
                          ),
                        )
                      : Image.network(
                          post.mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(t),
                        )
                : _placeholder(t),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    post.bodyPart ?? '운동',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatRelativeTime(post.createdAt),
                    style: TextStyle(fontSize: 12.5, color: t.faintText),
                  ),
                ],
              ),
              if (metrics.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final metric in metrics) _Chip(label: metric),
                  ],
                ),
              ],
              if (post.caption.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  post.caption,
                  style: TextStyle(fontSize: 14, height: 1.5, color: t.text),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder(AppTokens t) => Center(
    child: Icon(
      _isVideo ? Icons.videocam_outlined : Icons.article_outlined,
      size: 40,
      color: t.faintText,
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.mutedText,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LikerTile extends StatelessWidget {
  const _LikerTile({required this.liker});

  final PostReaction liker;

  @override
  Widget build(BuildContext context) => _PersonRow(
    name: liker.nickname,
    avatarUrl: liker.avatarUrl,
    trailing: formatRelativeTime(liker.createdAt),
  );
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) => _PersonRow(
    name: comment.authorName ?? '회원',
    avatarUrl: comment.authorAvatarUrl,
    trailing: formatRelativeTime(comment.createdAt),
    body: comment.body,
  );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.avatarUrl,
    required this.trailing,
    this.body,
  });

  final String name;
  final String? avatarUrl;
  final String trailing;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = avatarUrl ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.bg,
              shape: BoxShape.circle,
              border: Border.all(color: t.border),
            ),
            child: url.isEmpty
                ? Text(
                    initialOf(name),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  )
                : Image.network(
                    url,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.person_outline, color: t.faintText),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trailing,
                      style: TextStyle(fontSize: 12, color: t.faintText),
                    ),
                  ],
                ),
                if (body != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    body!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: t.text,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: t.mutedText,
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: AppSkeleton(height: 44, radius: 12),
  );
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Text(
      message,
      style: TextStyle(fontSize: 13.5, color: context.tokens.mutedText),
    ),
  );
}

/// 알림처럼 ID만 아는 곳에서 게시물 상세로 들어가는 진입점.
class PostDetailRoute extends ConsumerWidget {
  const PostDetailRoute({required this.postId, super.key});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(postByIdProvider(postId))
      .when(
        loading: () => const Scaffold(body: AppLoading()),
        error: (_, _) => Scaffold(
          appBar: AppBar(),
          body: const AppEmptyState(
            icon: Icons.error_outline,
            title: '게시물을 불러오지 못했습니다',
            message: '삭제되었거나 볼 수 없는 글일 수 있어요.',
          ),
        ),
        data: (post) => PostDetailPage(post: post),
      );
}
