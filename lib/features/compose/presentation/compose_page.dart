import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_tokens.dart';
import '../../auth/application/auth_service.dart';
import '../../feed/application/post_providers.dart';
import 'capture_flow.dart';
import '../../profile/application/profile_providers.dart';

/// Composer for a captured image or video.
class ComposePage extends ConsumerStatefulWidget {
  const ComposePage({required this.media, this.onPublished, super.key});

  final CapturedMedia media;
  final ValueChanged<String>? onPublished;

  @override
  ConsumerState<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends ConsumerState<ComposePage> {
  final _captionController = TextEditingController();
  bool _isPublishing = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    if (ref.read(authServiceProvider).currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      context.go('/login');
      return;
    }
    setState(() => _isPublishing = true);
    final result = await ref
        .read(postRepositoryProvider)
        .createPost(
          media: File(widget.media.file.path),
          isVideo: widget.media.isVideo,
          caption: _captionController.text,
        );
    if (!mounted) return;
    result.when(
      ok: (_) {
        widget.onPublished?.call(_captionController.text);
        // 내 프로필 그리드도 같이 갱신해야 방금 올린 글이 보인다.
        ref
          ..invalidate(publicFeedProvider)
          ..invalidate(myPostsProvider);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(const SnackBar(content: Text('게시되었습니다')));
        Navigator.pop(context);
      },
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
    if (mounted) setState(() => _isPublishing = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: t.text),
                ),
              ),
              Text('게시물 작성', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _MediaPreview(media: widget.media),
              const SizedBox(height: 16),
              TextField(
                key: const Key('compose-caption'),
                controller: _captionController,
                maxLines: 3,
                style: TextStyle(color: t.text),
                decoration: const InputDecoration(
                  hintText: '운동 이야기를 남겨보세요',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('publish-post'),
                onPressed: _isPublishing ? null : _publish,
                icon: _isPublishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_outlined),
                label: const Text('게시'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.media});
  final CapturedMedia media;

  @override
  Widget build(BuildContext context) {
    if (!media.isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(File(media.file.path), fit: BoxFit.cover),
        ),
      );
    }
    return _VideoPreview(path: media.file.path);
  }
}

/// 방금 찍은 영상을 그 자리에서 확인한다. 올리기 전에 뭘 찍었는지 봐야 한다.
class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.path});
  final String path;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final VideoPlayerController _controller = VideoPlayerController.file(
    File(widget.path),
  );
  late final Future<void> _ready = _controller.initialize();

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _toggle() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      if (_controller.value.isCompleted) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        final failed =
            snapshot.hasError ||
            (snapshot.connectionState == ConnectionState.done &&
                !_controller.value.isInitialized);
        if (snapshot.connectionState != ConnectionState.done || failed) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border),
              ),
              child: Center(
                child: failed
                    ? Icon(Icons.videocam_off_outlined, color: t.faintText)
                    : const CircularProgressIndicator(),
              ),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: GestureDetector(
              onTap: _toggle,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, child) => Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    child!,
                    if (!value.isPlaying)
                      Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 56,
                          color: t.text.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        );
      },
    );
  }
}
