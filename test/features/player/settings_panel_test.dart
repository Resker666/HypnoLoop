import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/settings.dart';
import 'package:hypnoloop/features/player/settings_panel.dart';

void main() {
  testWidgets('RGB dialog stays scrollable when rotated to landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPanel(
            settings: AppSettings.defaults(),
            onChanged: (_) {},
            onChangeEnd: () {},
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '背景'));
    await tester.tap(find.widgetWithText(OutlinedButton, '背景'));
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(800, 320));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('蓝'));
    await tester.pumpAndSettle();
    expect(find.text('蓝').hitTestable(), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
