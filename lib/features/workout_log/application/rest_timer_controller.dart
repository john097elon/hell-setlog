import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/workout.dart';

part 'rest_timer_controller.g.dart';

class RestTimerState {
  const RestTimerState(this.remainingSeconds, {this.isRunning = false});

  final int remainingSeconds;
  final bool isRunning;
}

/// Owns the rest countdown and releases its timer when the provider disposes.
@riverpod
class RestTimer extends _$RestTimer {
  Timer? _timer;

  @override
  RestTimerState build() {
    ref.onDispose(_stop);
    return const RestTimerState(0);
  }

  void start([int seconds = kDefaultRestSeconds]) {
    _stop();
    state = RestTimerState(seconds, isRunning: seconds > 0);
    if (seconds > 0) _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void addSeconds([int seconds = kRestTimerIncrementSeconds]) {
    state = RestTimerState(state.remainingSeconds + seconds, isRunning: true);
    _timer ??= Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void skip() {
    _stop();
    state = const RestTimerState(0);
  }

  void _tick(Timer _) {
    final next = state.remainingSeconds - 1;
    if (next <= 0) {
      skip();
    } else {
      state = RestTimerState(next, isRunning: true);
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}
