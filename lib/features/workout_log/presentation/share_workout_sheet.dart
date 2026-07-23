import 'package:flutter/material.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/theme/app_theme.dart';
import 'models/share_view_data.dart';
import 'widgets/record_ring_button.dart';

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

class _ShareWorkoutSheet extends StatefulWidget {
  const _ShareWorkoutSheet({required this.data});

  final ShareViewData data;

  @override
  State<_ShareWorkoutSheet> createState() => _ShareWorkoutSheetState();
}

class _ShareWorkoutSheetState extends State<_ShareWorkoutSheet> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _share() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.workoutSharedMock)),
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
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(
                  child: SizedBox(
                    width: 36,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
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
                          side: const BorderSide(color: AppColors.border),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                const _CameraPreviewPlaceholder(),
                const SizedBox(height: 16),
                const RecordRingButton(),
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
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share),
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

class _CameraPreviewPlaceholder extends StatelessWidget {
  const _CameraPreviewPlaceholder();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.videocam_outlined,
              size: 40,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.cameraPreviewMock,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    ),
  );
}
