import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/playback_clock.dart';

void main() {
  test('pause, background and speed changes preserve phase', () {
    final clock = PlaybackClock();
    addTearDown(clock.dispose);
    clock.advance(const Duration(seconds: 12));
    expect(clock.animationSeconds, 6);
    clock.setPlaying(false);
    clock.advance(const Duration(seconds: 30));
    expect(clock.animationSeconds, 6);
    clock.setForeground(false);
    clock.setPlaying(true);
    clock.advance(const Duration(seconds: 30));
    expect(clock.animationSeconds, 6);
    clock.setForeground(true);
    clock.setSpeed(2);
    clock.advance(const Duration(seconds: 1));
    expect(clock.animationSeconds, 8);
  });
  test('equal elapsed time at 60 and 120Hz produces the same phase', () {
    double simulate(int frames) {
      final clock = PlaybackClock();
      var previous = 0;
      for (var i = 1; i <= frames; i++) {
        final elapsed = (1000000 * i / frames).round();
        clock.advance(Duration(microseconds: elapsed - previous));
        previous = elapsed;
      }
      final result = clock.animationSeconds;
      clock.dispose();
      return result;
    }

    expect(simulate(60), closeTo(.5, 1e-9));
    expect(simulate(120), closeTo(simulate(60), 1e-9));
  });
  test('negative deltas and invalid speeds cannot reverse or poison time', () {
    final clock = PlaybackClock();
    addTearDown(clock.dispose);
    clock.setSpeed(double.infinity);
    clock.advance(const Duration(seconds: -1));
    expect(clock.animationSeconds, 0);
    clock.advance(const Duration(seconds: 1));
    expect(clock.animationSeconds, .5);
  });
}
