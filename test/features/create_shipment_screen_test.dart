import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/create/screens/create_shipment_screen.dart';
import 'package:lodbod/shared/providers/repository_providers.dart';

void main() {
  Finder fieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          shipmentRepositoryProvider.overrideWithValue(
            MockShipmentRepository(latency: Duration.zero),
          ),
        ],
        child: const MaterialApp(home: CreateShipmentScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();
  }

  testWidgets('validates each step and shows the limit without losing input',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(fieldWithHint('Kathmandu'), 'Kathmandu');
    await tester.enterText(
      fieldWithHint('Kalimati, Kathmandu'),
      'Kalimati, Kathmandu',
    );
    await tester.enterText(fieldWithHint('Pokhara'), 'Pokhara');
    await tester.enterText(
      fieldWithHint('Lakeside, Pokhara'),
      'Lakeside, Pokhara',
    );
    await tapNext(tester);

    await tester.enterText(
      fieldWithHint('Steel pipes, cement bags, furniture...'),
      'Steel pipes',
    );
    await tester.enterText(fieldWithHint('10'), '10');
    await tapNext(tester);

    await tester.enterText(
      fieldWithHint('Loading instructions, contact notes...'),
      'Call before arrival',
    );
    await tapNext(tester);

    await tapNext(tester);

    expect(find.text(AppStrings.step5Title), findsOneWidget);
    expect(find.text('Kathmandu · Kalimati, Kathmandu'), findsOneWidget);

    await tester.tap(find.text(AppStrings.submit));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.requestLimitTitle), findsOneWidget);
    expect(find.text(AppStrings.requestLimitMessage), findsOneWidget);

    await tester.tap(find.text(AppStrings.gotIt));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.step5Title), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text(AppStrings.previous));
      await tester.pumpAndSettle();
    }

    expect(find.text(AppStrings.step1Title), findsOneWidget);
    final pickup = tester.widget<TextField>(fieldWithHint('Kathmandu'));
    expect(pickup.controller?.text, 'Kathmandu');
  });

  testWidgets('blocks the first step until required fields are filled',
      (tester) async {
    await pumpForm(tester);

    await tapNext(tester);

    expect(find.text(AppStrings.fieldRequired), findsWidgets);
    expect(find.text(AppStrings.step1Title), findsOneWidget);
  });
}
