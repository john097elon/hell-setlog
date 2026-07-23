import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/workout.dart';
import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/theme/app_tokens.dart';

/// A mock recording control with local-only visual state.
class RecordRingButton extends StatefulWidget {
  const RecordRingButton({super.key});

  @override
  State<RecordRingButton> createState() => _RecordRingButtonState();
}

class _RecordRingButtonState extends State<RecordRingButton> {
  Timer? _timer;
  var _isRecording = false;
  var _elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _timer = Timer.periodic(kMockRecordTimerTick, (_) {
          if (mounted) setState(() => _elapsedSeconds++);
        });
      } else {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          label: _isRecording ? copy.recording : copy.tapToRecord,
          child: InkResponse(
            key: const Key('record-ring-button'),
            onTap: _toggleRecording,
            radius: 44,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.tokens.bg,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: context.tokens.brandLight, width: 3),
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.tokens.brand,
                  borderRadius: BorderRadius.circular(_isRecording ? 12 : 30),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRecording
              ? '${copy.recording} ${_formatElapsedTime()}'
              : copy.tapToRecord,
          key: const Key('recording-status'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  String _formatElapsedTime() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
