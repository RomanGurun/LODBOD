import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/theme/app_theme.dart';
import 'package:lodbod/features/auth/presentation/screens/splash_screen.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );
    // The indeterminate progress bar never settles, so pump the entrance
    // animation out instead of using pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('lays out without overflow on a small phone', (tester) async {
    await pumpAt(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.text('LODBOD'), findsOneWidget);
    expect(find.text('SHIPPER'), findsOneWidget);
  });

  testWidgets('lays out without overflow on a tablet', (tester) async {
    await pumpAt(tester, const Size(1024, 768));

    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without overflow in landscape', (tester) async {
    await pumpAt(tester, const Size(568, 320));

    expect(tester.takeException(), isNull);
  });
}
