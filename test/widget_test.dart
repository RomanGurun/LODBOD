import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/main.dart';

void main() {
  testWidgets('App boots into the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LodbodApp()));
    await tester.pump();

    expect(find.text('LODBOD'), findsOneWidget);
  });
}
