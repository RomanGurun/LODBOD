import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/data/mock/seed_data.dart';
import 'package:lodbod/data/models/shipment_model.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'package:lodbod/features/create/screens/create_shipment_screen.dart';
import 'package:lodbod/features/create/screens/order_placed_screen.dart';
import 'package:lodbod/shared/providers/repository_providers.dart';

import '../support/fake_auth.dart';

void main() {
  Finder fieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  MockShipmentRepository threeActiveRepository() {
    final seed = buildSeedShipments();
    return MockShipmentRepository(
      shipments: <ShipmentModel>[
        seed[0],
        seed[1],
        seed[3].copyWith(status: 'scheduled'),
      ],
      bids: buildSeedBids(),
      latency: Duration.zero,
    );
  }

  /// Pumps the create screen inside a minimal GoRouter so the post-submit
  /// navigation to the order confirmation screen works like production.
  Future<void> pumpForm(
    WidgetTester tester, {
    MockShipmentRepository? repository,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const CreateShipmentScreen(),
        ),
        GoRoute(
          path: '/order-placed',
          builder: (context, state) => state.extra is Shipment
              ? OrderPlacedScreen.fromShipment(state.extra! as Shipment)
              : const OrderPlacedScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          shipmentRepositoryProvider.overrideWithValue(
            repository ?? MockShipmentRepository(latency: Duration.zero),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();
  }

  Future<void> fillToReview(WidgetTester tester) async {
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
  }

  testWidgets('validates each step and shows the limit without losing input',
      (tester) async {
    await pumpForm(tester, repository: threeActiveRepository());
    await fillToReview(tester);

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

  testWidgets('creates a shipment and shows the confirmation', (tester) async {
    await pumpForm(tester);
    await fillToReview(tester);

    expect(find.text(AppStrings.step5Title), findsOneWidget);

    await tester.tap(find.text(AppStrings.submit));
    await tester.pumpAndSettle();

    // The order confirmation screen is shown only after real persistence.
    expect(find.text('Order placed'), findsOneWidget);
    // The reference appears in the header message and the summary row.
    expect(find.textContaining('LOD-1005'), findsWidgets);
  });

  testWidgets('blocks the first step until required fields are filled',
      (tester) async {
    await pumpForm(tester);

    await tapNext(tester);

    expect(find.text(AppStrings.fieldRequired), findsWidgets);
    expect(find.text(AppStrings.step1Title), findsOneWidget);
  });
}
