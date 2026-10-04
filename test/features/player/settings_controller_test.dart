import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/settings.dart';
import 'package:hypnoloop/features/player/settings_controller.dart';
import 'package:hypnoloop/features/player/settings_store.dart';

class MemoryStore implements SettingsStore {
  String? value;
  bool readFails = false, writeFails = false;
  int writes = 0;
  Completer<void>? delay;
  @override
  Future<String?> read() async {
    if (readFails) throw StateError('read failed');
    return value;
  }

  @override
  Future<void> write(String value) async {
    writes++;
    final gate = delay;
    delay = null;
    if (gate != null) await gate.future;
    if (writeFails) throw StateError('write failed');
    this.value = value;
  }
}

void main() {
  test(
    'missing, corrupted, non-map, and unreadable settings start with defaults',
    () async {
      for (final value in [null, 'broken', '[1, 2]', '{"schemaVersion":9}']) {
        final controller = SettingsController(MemoryStore()..value = value);
        await controller.load();
        expect(controller.settings.toJson(), AppSettings.defaults().toJson());
        controller.dispose();
      }
      final controller = SettingsController(MemoryStore()..readFails = true);
      await controller.load();
      expect(controller.settings.speed, .5);
      controller.dispose();
    },
  );
  test('all valid fields survive closing and recreating controller', () async {
    final store = MemoryStore();
    final expected = AppSettings.defaults()
        .preset(2)
        .copyWith(
          speed: 1.7,
          stripes: 7,
          density: 4.2,
          heartIntervalSeconds: .7,
          clockwise: false,
          showCenterHeart: true,
          centerHeartFraction: .18,
        );
    final first = SettingsController(store);
    await first.load();
    first.update(expected);
    await first.flush();
    first.dispose();
    final second = SettingsController(store);
    await second.load();
    expect(second.settings.toJson(), expected.toJson());
    second.dispose();
  });
  testWidgets(
    'rapid sliders debounce, commit flushes, disposal cancels timer',
    (tester) async {
      final store = MemoryStore();
      final controller = SettingsController(store);
      await controller.load();
      controller.update(controller.settings.copyWith(speed: .9));
      controller.update(controller.settings.copyWith(speed: 1.2));
      await tester.pump(const Duration(milliseconds: 199));
      expect(store.writes, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(store.writes, 1);
      controller.update(controller.settings.copyWith(speed: 1.8), commit: true);
      await tester.pump();
      expect(jsonDecode(store.value!)['speed'], 1.8);
      controller.update(controller.settings.copyWith(speed: 1.9));
      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(store.writes, 2);
    },
  );
  test('newer value wins even when an older write is delayed', () async {
    final gate = Completer<void>();
    final store = MemoryStore()..delay = gate;
    final controller = SettingsController(store);
    await controller.load();
    controller.update(controller.settings.copyWith(speed: .8));
    final firstFlush = controller.flush();
    await Future<void>.delayed(Duration.zero);
    controller.update(controller.settings.copyWith(speed: 1.6));
    final finalFlush = controller.flush();
    gate.complete();
    await Future.wait([firstFlush, finalFlush]);
    expect(jsonDecode(store.value!)['speed'], 1.6);
    expect(store.writes, 2);
    controller.dispose();
  });
  test(
    'write errors retain memory and clear after a successful retry',
    () async {
      final store = MemoryStore()..writeFails = true;
      final controller = SettingsController(store);
      await controller.load();
      controller.update(controller.settings.copyWith(speed: 1.3));
      await controller.flush();
      expect(controller.saveFailed, true);
      expect(controller.settings.speed, 1.3);
      store.writeFails = false;
      await controller.flush();
      expect(controller.saveFailed, false);
      expect(jsonDecode(store.value!)['speed'], 1.3);
      controller.dispose();
    },
  );
  test('dispose during write suppresses late notifications', () async {
    final gate = Completer<void>();
    final store = MemoryStore()..delay = gate;
    final controller = SettingsController(store);
    await controller.load();
    controller.update(controller.settings.copyWith(speed: 1.3));
    final flush = controller.flush();
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    gate.complete();
    await flush;
  });
}
