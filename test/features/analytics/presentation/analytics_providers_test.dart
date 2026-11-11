import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
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

  test('shipmentStatusCountsProvider counts every status', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final counts = container.read(shipmentStatusCountsProvider).requireValue;
    expect(counts[ShipmentStatus.inTransit], 1);
    expect(counts[ShipmentStatus.awaitingBids], 1);
    expect(counts[ShipmentStatus.delivered], 1);
    expect(counts[ShipmentStatus.cancelled], 1);
    expect(counts[ShipmentStatus.scheduled], 0);
    expect(counts[ShipmentStatus.open], 0);
  });

  test('monthlyShipmentCountsProvider buckets shipments by month', () async {
    final container = buildContainer();
    await container.read(shipmentNotifierProvider.future);

    final series =
        container.read(monthlyShipmentCountsProvider(6)).requireValue;

    expect(series, hasLength(6));
    // Seeded shipments are created within the last few days, so the current
    // month bucket holds all of them and older buckets are zero.
    final total = series.fold<int>(0, (sum, e) => sum + e.$2);
    expect(total, 4);
  });
}
