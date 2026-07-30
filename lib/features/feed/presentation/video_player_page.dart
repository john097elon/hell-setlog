import 'package:flutter/material.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

/// Full-screen media preview. Playback is intentionally a backlog item.
class VideoPlayerPage extends StatelessWidget {
  const VideoPlayerPage({
    required this.mediaUrl,
    required this.isVideo,
    super.key,
  });

  final String mediaUrl;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: isVideo
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (mediaUrl.isNotEmpty)
                          Image.network(mediaUrl, fit: BoxFit.contain)
                        else
                          Icon(
                            Icons.videocam_outlined,
                            color: t.faintText,
                            size: 48,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          '이 기기에서는 영상 미리보기만 제공됩니다',
                          style: TextStyle(color: t.mutedText),
                        ),
                      ],
                    )
                  : InteractiveViewer(
                      child: Image.network(
                        mediaUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: t.faintText,
                          size: 48,
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Semantics(
                button: true,
                label: '닫기',
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: t.text),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
