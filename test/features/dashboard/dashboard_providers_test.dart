import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/dashboard/providers/dashboard_providers.dart';
import 'package:lodbod/features/shipments/providers/shipment_notifier.dart';
import 'package:lodbod/shared/providers/repository_providers.dart';

void main() {
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: <Override>[
        shipmentRepositoryProvider.overrideWithValue(
          MockShipmentRepository(latency: Duration.zero),
        ),
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
    expect(action?.bidCount, 3);
  });

  test('nextPickupShipmentProvider picks the nearest future pickup', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final next = container.read(nextPickupShipmentProvider).requireValue;

    expect(next?.reference, 'LOD-1004');
  });
}
