import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_providers.dart';
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

  test('filteredShipmentsProvider matches query and status', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final byQuery = container
        .read(filteredShipmentsProvider(const ShipmentFilter(query: 'birgunj')))
        .requireValue;
    expect(byQuery, hasLength(1));
    expect(byQuery.single.reference, 'LOD-1002');

    final delivered = container
        .read(
          filteredShipmentsProvider(
            const ShipmentFilter(status: ShipmentStatus.delivered),
          ),
        )
        .requireValue;
    expect(delivered, hasLength(1));
    expect(delivered.single.reference, 'LOD-1003');
  });

  test('filteredShipmentsProvider supports the active-only grouping',
      () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final active = container
        .read(
          filteredShipmentsProvider(const ShipmentFilter(activeOnly: true)),
        )
        .requireValue;

    // Seeds: in_transit + awaiting_bids are active; delivered and cancelled
    // are excluded.
    expect(active.map((s) => s.reference), unorderedEquals(<String>[
      'LOD-1001',
      'LOD-1002',
    ]));
  });

  test('shipmentByIdProvider resolves one shipment from the list', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final shipment = container.read(shipmentByIdProvider('2')).requireValue;
    expect(shipment?.reference, 'LOD-1002');

    final missing = container.read(shipmentByIdProvider('nope')).requireValue;
    expect(missing, isNull);
  });
}
