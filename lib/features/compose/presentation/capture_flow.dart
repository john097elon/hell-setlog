import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_tokens.dart';
import 'compose_page.dart';

/// Opens camera or gallery selection, then the local-only post composer.
Future<void> openCaptureFlow(BuildContext context) async {
  final action = await showModalBottomSheet<_CaptureAction>(
    context: context,
    backgroundColor: context.tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CaptureActionSheet(),
  );
  if (!context.mounted || action == null) return;

  final picker = ImagePicker();
  final media = await _capture(context, picker, action);
  if (!context.mounted || media == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ComposePage(media: media),
  );
}

Future<CapturedMedia?> _capture(
  BuildContext context,
  ImagePicker picker,
  _CaptureAction action,
) async {
  if (action != _CaptureAction.gallery &&
      !await _hasCapturePermissions(context, action.isVideo)) {
    return null;
  }
  try {
    final file = switch (action) {
      _CaptureAction.video => await picker.pickVideo(
        source: ImageSource.camera,
      ),
      _CaptureAction.photo => await picker.pickImage(
        source: ImageSource.camera,
      ),
      _CaptureAction.gallery => await picker.pickMedia(),
    };
    if (file == null) return null;
    return CapturedMedia(file: file, isVideo: action.isVideo || _isVideo(file));
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('미디어를 불러오지 못했습니다.')));
    }
    return null;
  }
}

Future<bool> _hasCapturePermissions(
  BuildContext context,
  bool needsMicrophone,
) async {
  final permissions = <Permission>[
    Permission.camera,
    if (needsMicrophone) Permission.microphone,
  ];
  final statuses = await permissions.request();
  final granted = statuses.values.every(
    (status) => status.isGranted || status.isLimited,
  );
  if (granted || !context.mounted) return granted;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('촬영하려면 카메라 권한이 필요합니다.'),
      action: SnackBarAction(label: '설정', onPressed: openAppSettings),
    ),
  );
  return false;
}

bool _isVideo(XFile file) =>
    file.mimeType?.startsWith('video/') == true ||
    RegExp(r'\.(mp4|mov|avi|mkv)$', caseSensitive: false).hasMatch(file.path);

class CapturedMedia {
  const CapturedMedia({required this.file, required this.isVideo});

  final XFile file;
  final bool isVideo;
}

enum _CaptureAction {
  video,
  photo,
  gallery;

  bool get isVideo => this == video;
}

class _CaptureActionSheet extends StatelessWidget {
  const _CaptureActionSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SafeArea(
      top: false,
      child: Padding(
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
            const SizedBox(height: 16),
            Text('새 게시물', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.videocam_outlined,
              label: '영상 촬영',
              onTap: () => Navigator.pop(context, _CaptureAction.video),
            ),
            _ActionTile(
              icon: Icons.photo_camera_outlined,
              label: '사진 촬영',
              onTap: () => Navigator.pop(context, _CaptureAction.photo),
            ),
            _ActionTile(
              icon: Icons.photo_library_outlined,
              label: '갤러리에서 선택',
              onTap: () => Navigator.pop(context, _CaptureAction.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Icon(icon, color: t.text),
      ),
      title: Text(label, style: TextStyle(color: t.text)),
      trailing: Icon(Icons.chevron_right_rounded, color: t.faintText),
      onTap: onTap,
    );
  }
}
