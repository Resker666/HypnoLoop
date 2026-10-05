import 'dart:async';
import 'dart:ui' show SemanticsAction;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/app.dart';
import '../../app_test.dart' show AppDisplay;
import 'settings_controller_test.dart' show MemoryStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hypnoloop/launcher-icon');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      HypnoLoopApp(store: MemoryStore(), display: AppDisplay()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip('暂停'));
    await tester.pump();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('桌面图标'));
    await tester.pumpAndSettle();
    expect(find.text('更换桌面图标'), findsOneWidget);
  }

  bool selected(WidgetTester tester, String id) => tester
      .widget<Semantics>(find.byKey(Key('launcher-icon-$id')))
      .properties
      .selected!;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('icon picker reads the system selection, switches and resets', (
    tester,
  ) async {
    var actual = 'c';
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCurrent') return actual;
      expect(call.method, 'setIcon');
      expect(call.arguments, containsPair('id', isIn(['a', 'b'])));
      actual = (call.arguments as Map)['id'] as String;
      return actual;
    });
    addTearDown(() => close(tester));
    final semantics = tester.ensureSemantics();
    try {
      await open(tester);
      await tester.ensureVisible(find.byKey(const Key('launcher-icon-a')));
      await tester.pumpAndSettle();
      expect(selected(tester, 'c'), isTrue);
      expect(selected(tester, 'b'), isFalse);
      expect(
        tester
            .getSemantics(find.byKey(const Key('launcher-icon-a')))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'TalkBack users must be able to activate an icon choice',
      );
      await tester.tap(find.byKey(const Key('launcher-icon-a')));
      await tester.pumpAndSettle();
      expect(selected(tester, 'a'), isTrue);
      expect(selected(tester, 'c'), isFalse);
      await tester.ensureVisible(find.text('恢复默认'));
      await tester.tap(find.text('恢复默认'));
      await tester.pumpAndSettle();
      expect(selected(tester, 'b'), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reopening the app reloads the icon enabled by the system', (
    tester,
  ) async {
    var actual = 'd';
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCurrent') return actual;
      expect(call.method, 'setIcon');
      expect(call.arguments, {'id': 'a'});
      actual = 'a';
      return actual;
    });
    addTearDown(() => close(tester));
    await open(tester);
    expect(selected(tester, 'd'), isTrue);
    await tester.ensureVisible(find.byKey(const Key('launcher-icon-a')));
    await tester.tap(find.byKey(const Key('launcher-icon-a')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await open(tester);
    expect(selected(tester, 'a'), isTrue);
    expect(selected(tester, 'b'), isFalse);
  });

  testWidgets('failed icon switch keeps the real selection and can retry', (
    tester,
  ) async {
    final pending = Completer<String>();
    var actual = 'd', attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCurrent') return actual;
      expect(call.method, 'setIcon');
      expect(call.arguments, {'id': 'a'});
      if (++attempts == 1) return pending.future;
      actual = 'a';
      return actual;
    });
    addTearDown(() => close(tester));
    await open(tester);
    await tester.ensureVisible(find.byKey(const Key('launcher-icon-a')));
    await tester.tap(find.byKey(const Key('launcher-icon-a')));
    await tester.pump();
    expect(selected(tester, 'd'), isTrue);
    final buttons = find.descendant(
      of: find.byKey(const Key('launcher-icon-a')),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(buttons).onPressed, isNull);
    pending.completeError(PlatformException(code: 'switch-failed'));
    await tester.pumpAndSettle();
    expect(selected(tester, 'd'), isTrue);
    expect(find.text('图标切换失败，请重试'), findsOneWidget);
    await tester.tap(find.byKey(const Key('launcher-icon-a')));
    await tester.pumpAndSettle();
    expect(selected(tester, 'a'), isTrue);
    expect(find.text('图标切换失败，请重试'), findsNothing);
  });

  testWidgets('unknown native icon never highlights an assumed default', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'unknown');
    addTearDown(() => close(tester));
    await open(tester);
    expect(find.text('无法读取当前图标，请重试'), findsOneWidget);
    expect(selected(tester, 'b'), isFalse);
    expect(find.text('重试'), findsOneWidget);
  });
}
