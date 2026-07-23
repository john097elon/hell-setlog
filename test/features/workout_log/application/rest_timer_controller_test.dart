import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/features/workout_log/application/rest_timer_controller.dart';

void main() {
  test('counts down to zero, adds 15 seconds, and skips', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(restTimerProvider, (_, _) {});
      final timer = container.read(restTimerProvider.notifier);

      timer.start(2);
      async.elapse(const Duration(seconds: 1));
      expect(container.read(restTimerProvider).remainingSeconds, 1);
      timer.addSeconds();
      expect(container.read(restTimerProvider).remainingSeconds, 16);
      timer.skip();
      expect(container.read(restTimerProvider).isRunning, isFalse);
      expect(container.read(restTimerProvider).remainingSeconds, 0);

      timer.start(1);
      async.elapse(const Duration(seconds: 1));
      expect(container.read(restTimerProvider).isRunning, isFalse);
    });
  });
}
