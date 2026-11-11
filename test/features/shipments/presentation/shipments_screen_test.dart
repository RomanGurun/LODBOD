import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/shipments/presentation/screens/shipments_screen.dart';
import 'package:lodbod/core/di/repository_providers.dart';

import '../../../support/fake_auth.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          shipmentRepositoryProvider.overrideWithValue(
            MockShipmentRepository(latency: Duration.zero),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(home: ShipmentsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('filters the list by search query and status', (tester) async {
    await pumpScreen(tester);

    expect(find.text('LOD-1001'), findsOneWidget);
    expect(find.text('LOD-1002'), findsOneWidget);
    expect(find.text('LOD-1003'), findsOneWidget);
    expect(find.text('LOD-1004'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'birgunj');
    await tester.pumpAndSettle();

    expect(find.text('LOD-1002'), findsOneWidget);
    expect(find.text('LOD-1001'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.widgetWithText(ChoiceChip, 'Cancelled'),
      find.byType(ListView).first,
      const Offset(-200, 0),
    );
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Cancelled'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cancelled'));
    await tester.pumpAndSettle();

    expect(find.text('LOD-1004'), findsOneWidget);
    expect(find.text('LOD-1001'), findsNothing);
    expect(find.text('LOD-1002'), findsNothing);
    expect(find.text('LOD-1003'), findsNothing);
  });
}
