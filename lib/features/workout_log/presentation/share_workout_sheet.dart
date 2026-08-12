import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/theme/app_tokens.dart';
import '../../feed/application/post_providers.dart';
import 'models/share_view_data.dart';
import '../../profile/application/profile_providers.dart';

/// Shows the local-only video-sharing mock after a workout completes.
Future<void> showShareWorkoutSheet(
  BuildContext context, {
  ShareViewData data = ShareViewData.mock,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _ShareWorkoutSheet(data: data),
);

class _ShareWorkoutSheet extends ConsumerStatefulWidget {
  const _ShareWorkoutSheet({required this.data});

  final ShareViewData data;

  @override
  ConsumerState<_ShareWorkoutSheet> createState() => _ShareWorkoutSheetState();
}

class _ShareWorkoutSheetState extends ConsumerState<_ShareWorkoutSheet> {
  final _captionController = TextEditingController();
  bool _sharing = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// 기록 요약을 실제 게시물로 남긴다. 미디어 없이도 공유된다.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final caption = _captionController.text.trim();
    final result = await ref
        .read(postRepositoryProvider)
        .createPost(
          caption: caption.isEmpty ? '오늘 운동 완료' : caption,
          bodyPart: widget.data.bodyPart,
          sessionId: widget.data.sessionId,
          volumeKg: widget.data.volumeKg,
          durationMin: widget.data.durationMin,
          prLabel: widget.data.prLabel,
          xp: widget.data.xp,
        );
    if (!mounted) return;
    setState(() => _sharing = false);
    result.when(
      ok: (_) {
        // 내 프로필 그리드도 같이 갱신해야 방금 올린 글이 보인다.
        ref
          ..invalidate(publicFeedProvider)
          ..invalidate(myPostsProvider);
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(content: Text('피드에 공유했습니다.')));
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: context.tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: SizedBox(
                    width: 36,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.tokens.border,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: copy.close,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Text(
                  copy.shareWorkout,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.data.workoutTags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          side: BorderSide(color: context.tokens.border),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: copy.shareCaptionHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('share-to-feed-button'),
                  onPressed: _sharing ? null : _share,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(copy.shareToFeed),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
