import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';
import 'package:lodbod/core/di/repository_providers.dart';

import '../../../support/fake_auth.dart';

void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: <Override>[
        shipmentRepositoryProvider.overrideWithValue(
          MockShipmentRepository(latency: Duration.zero),
        ),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('recentShipmentsProvider sorts by updatedAt and caps at three',
      () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final recent = container.read(recentShipmentsProvider).requireValue;

    expect(recent, hasLength(3));
    expect(
      recent.map((shipment) => shipment.reference),
      ['LOD-1001', 'LOD-1004', 'LOD-1002'],
    );
  });

  test(
      'actionRequiredShipmentProvider picks the bidding shipment with the '
      'most bids', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final action = container.read(actionRequiredShipmentProvider).requireValue;

    expect(action?.reference, 'LOD-1002');
    expect(action?.bidCount, 2);
  });

  test('nextPickupShipmentProvider picks the nearest future pickup', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final next = container.read(nextPickupShipmentProvider).requireValue;

    expect(next?.reference, 'LOD-1004');
  });
}
