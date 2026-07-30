import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/features/feed/application/post_providers.dart';

/// Shows moderation actions for a post.
Future<void> showPostActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  required String authorId,
  required bool isMine,
}) async {
  final action = await showModalBottomSheet<_PostAction>(
    context: context,
    builder: (_) => _PostActionsSheet(isMine: isMine),
  );
  if (!context.mounted || action == null || action == _PostAction.cancel) {
    return;
  }
  final repository = ref.read(postRepositoryProvider);
  switch (action) {
    case _PostAction.delete:
      if (!await _confirm(context, '게시물을 삭제할까요?', '삭제') || !context.mounted) {
        return;
      }
      await _handle(
        context,
        repository.deletePost(postId),
        ref,
        '게시물을 삭제했습니다.',
      );
      return;
    case _PostAction.report:
      final reason = await _reportReason(context);
      if (reason != null && context.mounted) {
        await _handle(
          context,
          repository.reportPost(postId, reason),
          ref,
          '신고가 접수되었습니다.',
        );
      }
      return;
    case _PostAction.block:
      if (!await _confirm(context, '이 사용자를 차단할까요?', '차단') || !context.mounted) {
        return;
      }
      await _handle(
        context,
        repository.blockUser(authorId),
        ref,
        '사용자를 차단했습니다.',
      );
      return;
    case _PostAction.cancel:
      return;
  }
}

enum _PostAction { delete, report, block, cancel }

class _PostActionsSheet extends StatelessWidget {
  const _PostActionsSheet({required this.isMine});

  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      child: Container(
        color: t.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(width: 36, height: 4, color: t.borderStrong),
            const SizedBox(height: 12),
            if (isMine)
              _ActionTile(
                label: '삭제',
                color: t.like,
                onTap: () => Navigator.pop(context, _PostAction.delete),
              )
            else ...<Widget>[
              _ActionTile(
                label: '신고',
                color: t.text,
                onTap: () => Navigator.pop(context, _PostAction.report),
              ),
              _ActionTile(
                label: '이 사용자 차단',
                color: t.like,
                onTap: () => Navigator.pop(context, _PostAction.block),
              ),
            ],
            _ActionTile(
              label: '취소',
              color: t.mutedText,
              onTap: () => Navigator.pop(context, _PostAction.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ),
  );
}

Future<bool> _confirm(
  BuildContext context,
  String message,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> _reportReason(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final reason in <String>['스팸', '부적절한 콘텐츠', '괴롭힘', '기타'])
              ListTile(
                title: Text(reason),
                onTap: () => Navigator.pop(sheetContext, reason),
              ),
          ],
        ),
      ),
    );

Future<void> _handle(
  BuildContext context,
  Future<Result<void, Failure>> operation,
  WidgetRef ref,
  String successMessage,
) async {
  final result = await operation;
  if (!context.mounted) return;
  result.when(
    ok: (_) {
      ref.invalidate(publicFeedProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    },
    err: (failure) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message))),
  );
}
