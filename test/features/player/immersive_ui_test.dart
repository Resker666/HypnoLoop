import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/app.dart';
import 'package:hypnoloop/features/player/mode_selector.dart';
import '../../app_test.dart' show AppDisplay;
import 'settings_controller_test.dart' show MemoryStore;

void main() {
  Future<void> open(WidgetTester tester, MemoryStore store) async {
    await tester.pumpWidget(HypnoLoopApp(store: store, display: AppDisplay()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip('暂停'));
    await tester.pump();
  }

  Future<void> reset(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  }

  // Catches bringing the long settings list back onto the home screen, or
  // shrinking/clipping the dock so its actions require a scroll to reach.
  testWidgets(
    'home controls fit without scrolling on compact and wide screens',
    (tester) async {
      addTearDown(() => reset(tester));
      for (final size in [
        const Size(320, 640),
        const Size(390, 844),
        const Size(844, 390),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await open(tester, MemoryStore());
        expect(find.byTooltip('调整').hitTestable(), findsOneWidget);
        expect(find.byTooltip('设置').hitTestable(), findsOneWidget);
        expect(find.byType(Slider), findsNothing);
        expect(find.text('条纹数量'), findsNothing);
        expect(find.byType(SingleChildScrollView), findsNothing);
        final start = find.byKey(const Key('start-fullscreen'));
        expect(start.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(start);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
        expect(
          tester
              .getSize(find.byKey(const Key('toggle-preview-playback')))
              .height,
          greaterThanOrEqualTo(76),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  // Catches applying edits to a stale modal snapshot or wiring the shape/color
  // tabs to the wrong controls; the actual App storage is the observable result.
  testWidgets('adjustment tabs edit and persist the active visual parameters', (
    tester,
  ) async {
    addTearDown(() => reset(tester));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final store = MemoryStore();
    await open(tester, store);
    await tester.tap(find.text('爱心'));
    await tester.pump();
    await tester.tap(find.byTooltip('调整'));
    await tester.pumpAndSettle();
    expect(find.text('扩散间隔'), findsOneWidget);
    expect(find.text('条纹数量'), findsNothing);
    expect(find.text('背景'), findsNothing);
    await tester.drag(find.byType(Slider).first, const Offset(50, 0));
    await tester.pump();
    await tester.drag(find.byType(Slider).last, const Offset(50, 0));
    await tester.pump();
    await tester.tap(find.text('配色'));
    await tester.pumpAndSettle();
    expect(find.text('背景'), findsOneWidget);
    expect(find.text('扩散间隔'), findsNothing);
    await tester.tap(find.widgetWithText(ActionChip, '紫黑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('参数'));
    await tester.pumpAndSettle();
    expect(find.text('条纹数量'), findsOneWidget);
    expect(find.text('扩散间隔'), findsNothing);
    await tester.tap(find.byTooltip('关闭设置'));
    await tester.pumpAndSettle();
    final saved = jsonDecode(store.value!) as Map<String, dynamic>;
    expect(saved['kind'], 'spiral');
    expect(saved['backgroundArgb'], 0xFF130D24);
    expect(saved['foregroundArgb'], 0xFFAE8BFA);
    expect(saved['speed'], greaterThan(.5));
    expect(saved['heartIntervalSeconds'], greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  // Catches a fixed-height control bar that clips with larger system text.
  testWidgets('large text fits compact landscape including system safe areas', (
    tester,
  ) async {
    addTearDown(() => reset(tester));
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    for (final scenario in [
      (const Size(640, 320), 1.0),
      (const Size(640, 320), 1.4),
      (const Size(640, 360), 1.4),
      (const Size(640, 320), 2.0),
      (const Size(480, 320), 2.0),
    ]) {
      await tester.binding.setSurfaceSize(scenario.$1);
      tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
      await open(tester, MemoryStore());
      expect(tester.takeException(), isNull, reason: '$scenario');
      final modeBounds = tester.getRect(find.byType(ModeSelector));
      for (final mode in ['螺旋', '爱心']) {
        final label = find.text(mode);
        expect(label.hitTestable(), findsOneWidget, reason: '$scenario');
        final labelBounds = tester.getRect(label);
        expect(modeBounds.contains(labelBounds.topLeft), isTrue);
        expect(modeBounds.contains(labelBounds.bottomRight), isTrue);
      }
      for (final finder in [
        find.byKey(const Key('start-fullscreen')),
        find.byTooltip('调整'),
        find.byTooltip('继续'),
        find.byKey(const Key('toggle-preview-playback')),
      ]) {
        expect(finder.hitTestable(), findsOneWidget, reason: '$scenario');
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThanOrEqualTo(24), reason: '$scenario');
        expect(
          rect.bottom,
          lessThanOrEqualTo(scenario.$1.height - 24),
          reason: '$scenario',
        );
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$scenario');
        expect(
          rect.right,
          lessThanOrEqualTo(scenario.$1.width),
          reason: '$scenario',
        );
      }
      expect(find.byType(SingleChildScrollView), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('large text keeps home actions and adjustment controls usable', (
    tester,
  ) async {
    addTearDown(() => reset(tester));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await open(tester, MemoryStore());
    expect(
      find.byKey(const Key('start-fullscreen')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byTooltip('调整').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('调整'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('中心爱心'));
    await tester.tap(find.text('中心爱心'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('爱心大小'));
    expect(find.text('爱心大小').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
