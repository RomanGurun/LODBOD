import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/providers/shipment_notifier.dart';
import 'package:lodbod/features/shipments/providers/shipment_providers.dart';
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

  test('dashboardStatsProvider derives counts from the shipment list',
      () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final stats = container.read(dashboardStatsProvider).requireValue;

    expect(stats.total, 4);
    expect(stats.active, 2);
    expect(stats.awaitingBids, 1);
    expect(stats.completed, 2);

    final counts = container.read(shipmentStatusCountsProvider).requireValue;
    expect(counts[ShipmentStatus.inTransit], 1);
    expect(counts[ShipmentStatus.awaitingBids], 1);
    expect(counts[ShipmentStatus.delivered], 1);
    expect(counts[ShipmentStatus.cancelled], 1);
    expect(counts[ShipmentStatus.scheduled], 0);
    expect(counts[ShipmentStatus.open], 0);
  });

  test('recentShipmentsProvider returns at most three shipments', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final recent = container.read(recentShipmentsProvider).requireValue;

    expect(recent, hasLength(3));
    expect(
      recent.map((shipment) => shipment.reference),
      ['LOD-1004', 'LOD-1002', 'LOD-1001'],
    );
  });

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

  test('shipmentByIdProvider and shipmentBidsProvider resolve one shipment',
      () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final shipment = container.read(shipmentByIdProvider('2')).requireValue;
    expect(shipment?.reference, 'LOD-1002');

    final bids = container.read(shipmentBidsProvider('2')).requireValue;
    expect(bids, hasLength(2));

    final missing = container.read(shipmentByIdProvider('nope')).requireValue;
    expect(missing, isNull);
  });
}
