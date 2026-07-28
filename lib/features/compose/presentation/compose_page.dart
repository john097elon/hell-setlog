import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import 'capture_flow.dart';

/// Local-only composer for a captured image or video.
class ComposePage extends StatefulWidget {
  const ComposePage({required this.media, this.onPublished, super.key});

  final CapturedMedia media;
  final ValueChanged<String>? onPublished;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _publish() {
    widget.onPublished?.call(_captionController.text);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    // TODO(P3): upload media and persist the post before confirming publication.
    messenger.showSnackBar(const SnackBar(content: Text('게시되었습니다')));
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
                onPressed: _publish,
                icon: const Icon(Icons.publish_outlined),
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
    final t = context.tokens;
    if (!media.isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(File(media.file.path), fit: BoxFit.cover),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            size: 48,
            color: t.text,
          ),
        ),
      ),
    );
  }
}
