import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/main.dart';

void main() {
  testWidgets('App boots into the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LodbodApp()));
    await tester.pump();

    expect(find.text('LODBOD'), findsOneWidget);

    // Let the splash gate timer fire so the test ends without pending timers.
    await tester.pump(AppDurations.splash);
    await tester.pumpAndSettle();
  });
}
