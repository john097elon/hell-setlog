import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/post_comment.dart';
import '../application/post_providers.dart';
import '../../../core/formatting/app_format.dart';

/// 게시물 댓글을 읽고 남기는 하단 시트를 연다.
Future<void> showCommentSheet(BuildContext context, {required String postId}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _CommentSheet(postId: postId),
      ),
    );

class _CommentSheet extends ConsumerStatefulWidget {
  const _CommentSheet({required this.postId});

  final String postId;

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  List<PostComment>? _comments;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ref
        .read(postRepositoryProvider)
        .fetchComments(widget.postId);
    if (!mounted) return;
    result.when(
      ok: (items) => setState(() {
        _comments = items;
        _loading = false;
      }),
      err: (_) => setState(() {
        _comments = const <PostComment>[];
        _loading = false;
      }),
    );
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await ref
        .read(postRepositoryProvider)
        .addComment(widget.postId, body);
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      ok: (comment) {
        _controller.clear();
        setState(() => _comments = <PostComment>[...?_comments, comment]);
        ref.invalidate(publicFeedProvider);
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final comments = _comments ?? const <PostComment>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Text(
                  '댓글',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const AppLoading()
                : comments.isEmpty
                ? const AppEmptyState(
                    icon: Icons.mode_comment_outlined,
                    title: '첫 댓글을 남겨보세요',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: comments.length,
                    itemBuilder: (context, index) => Column(
                      children: <Widget>[
                        if (index > 0) const AppHairline(indent: 44),
                        _CommentTile(comment: comments[index]),
                      ],
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: '댓글 입력'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = comment.authorName ?? '회원';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.bg,
              shape: BoxShape.circle,
              border: Border.all(color: t.border),
            ),
            child: Text(
              initialOf(name),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  comment.body,
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: t.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
