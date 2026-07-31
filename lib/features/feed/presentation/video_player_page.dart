import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/theme/app_tokens.dart';

/// 영상은 전체 화면으로 재생하고 사진은 확대 가능한 원본으로 보여준다.
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({
    required this.mediaUrl,
    required this.isVideo,
    this.controller,
    this.initializeController,
    super.key,
  });

  final String mediaUrl;
  final bool isVideo;

  /// 실제 네트워크 없이 상태를 검증할 때 주입하는 컨트롤러다.
  final VideoPlayerController? controller;

  /// 테스트에서 플랫폼 초기화를 대체한다.
  final Future<void> Function(VideoPlayerController)? initializeController;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  bool _showControls = true;
  bool _playbackFailed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isVideo) return;

    _controller = widget.controller;
    if (_controller == null) {
      final uri = Uri.tryParse(widget.mediaUrl);
      if (uri == null || !uri.hasScheme) return;
      _controller = VideoPlayerController.networkUrl(uri);
    }
    _initialization = _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = _controller!;
    final initializeController = widget.initializeController;
    if (initializeController == null) {
      await controller.initialize();
    } else {
      await initializeController(controller);
    }
    if (mounted) await controller.play();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller!;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        if (controller.value.isCompleted) {
          await controller.seekTo(Duration.zero);
        }
        await controller.play();
      }
    } on Object {
      if (mounted) setState(() => _playbackFailed = true);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: widget.isVideo ? _buildVideo(context) : _buildPhoto(context),
      ),
    );
  }

  Widget _buildVideo(BuildContext context) {
    final initialization = _initialization;
    if (initialization == null) {
      return _buildStatus(
        context,
        Icon(Icons.error_outline, color: context.tokens.faintText, size: 48),
        context.l10n.videoPlaybackError,
      );
    }

    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildStatus(
            context,
            Icon(
              Icons.error_outline,
              color: context.tokens.faintText,
              size: 48,
            ),
            context.l10n.videoPlaybackError,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildStatus(
            context,
            Semantics(
              label: context.l10n.videoLoading,
              child: const CircularProgressIndicator(),
            ),
          );
        }

        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller!,
          builder: (context, value, _) {
            if (value.hasError || _playbackFailed) {
              return _buildStatus(
                context,
                Icon(
                  Icons.error_outline,
                  color: context.tokens.faintText,
                  size: 48,
                ),
                context.l10n.videoPlaybackError,
              );
            }
            if (!value.isInitialized) {
              return _buildStatus(
                context,
                Semantics(
                  label: context.l10n.videoLoading,
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            return _buildPlayer(context, value);
          },
        );
      },
    );
  }

  Widget _buildPlayer(BuildContext context, VideoPlayerValue value) {
    final t = context.tokens;
    final remaining = value.duration - value.position;
    final remainingLabel = _formatDuration(
      remaining.isNegative ? Duration.zero : remaining,
    );

    return GestureDetector(
      key: const Key('video-player-surface'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          if (_showControls)
            IgnorePointer(
              child: ColoredBox(color: t.bg.withValues(alpha: 0.24)),
            ),
          if (value.isBuffering)
            Center(
              child: Semantics(
                label: context.l10n.videoLoading,
                child: const CircularProgressIndicator(),
              ),
            ),
          if (_showControls) _buildCloseButton(context),
          if (_showControls)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.bg.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        colors: VideoProgressColors(
                          playedColor: t.brand,
                          bufferedColor: t.mutedText,
                          backgroundColor: t.border,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          IconButton(
                            tooltip: value.isPlaying
                                ? context.l10n.videoPause
                                : context.l10n.videoPlay,
                            onPressed: _togglePlayback,
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: t.text,
                            ),
                          ),
                          const Spacer(),
                          Semantics(
                            label: context.l10n.videoRemainingTime(
                              remainingLabel,
                            ),
                            child: Text(
                              '-$remainingLabel',
                              style: TextStyle(
                                color: t.text,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Center(
        child: InteractiveViewer(
          child: Image.network(
            widget.mediaUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              color: context.tokens.faintText,
              size: 48,
            ),
          ),
        ),
      ),
      _buildCloseButton(context),
    ],
  );

  Widget _buildStatus(
    BuildContext context,
    Widget indicator, [
    String? message,
  ]) {
    final t = context.tokens;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              indicator,
              if (message != null) ...<Widget>[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.mutedText),
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildCloseButton(context),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) => Positioned(
    top: 8,
    left: 8,
    child: IconButton(
      tooltip: context.l10n.close,
      onPressed: () => Navigator.pop(context),
      icon: Icon(Icons.close, color: context.tokens.text),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    ),
  );
}

String _formatDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  final seconds = value.inSeconds.remainder(60);
  final minuteLabel = hours > 0
      ? minutes.toString().padLeft(2, '0')
      : '${value.inMinutes}';
  final prefix = hours > 0 ? '$hours:' : '';
  return '$prefix$minuteLabel:${seconds.toString().padLeft(2, '0')}';
}
