import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/data/mock/seed_data.dart';
import 'package:lodbod/data/models/shipment_model.dart';
import 'package:lodbod/domain/enums/bid_status.dart';
import 'package:lodbod/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/providers/shipment_notifier.dart';
import 'package:lodbod/shared/providers/repository_providers.dart';

import '../support/fixtures.dart';

void main() {
  ProviderContainer containerWith(MockShipmentRepository repository) {
    final container = ProviderContainer(
      overrides: <Override>[
        shipmentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('build loads the repository shipments', () async {
    final container =
        containerWith(MockShipmentRepository(latency: Duration.zero));

    final shipments = await container.read(shipmentNotifierProvider.future);

    expect(shipments, hasLength(4));
  });

  test('createShipment appends the created shipment', () async {
    final repository = MockShipmentRepository(
      shipments: buildSeedShipments().take(2).toList(),
      bids: const [],
      latency: Duration.zero,
    );
    final container = containerWith(repository);
    await container.read(shipmentNotifierProvider.future);

    final created = await container
        .read(shipmentNotifierProvider.notifier)
        .createShipment(validDraft());

    final shipments =
        container.read(shipmentNotifierProvider).valueOrNull ?? const [];
    expect(shipments, hasLength(3));
    expect(shipments.first.id, created.id);
    expect(created.status, ShipmentStatus.open);
  });

  test('createShipment enforces the three-active limit', () async {
    final seed = buildSeedShipments();
    final repository = MockShipmentRepository(
      shipments: <ShipmentModel>[
        seed[0],
        seed[1],
        seed[3].copyWith(status: 'scheduled'),
      ],
      bids: const [],
      latency: Duration.zero,
    );
    final container = containerWith(repository);
    await container.read(shipmentNotifierProvider.future);

    await expectLater(
      container
          .read(shipmentNotifierProvider.notifier)
          .createShipment(validDraft()),
      throwsA(isA<LimitException>()),
    );

    expect(
      container.read(shipmentNotifierProvider).valueOrNull,
      hasLength(3),
    );
  });

  test('acceptBid updates the shipment from the repository result', () async {
    final container =
        containerWith(MockShipmentRepository(latency: Duration.zero));
    await container.read(shipmentNotifierProvider.future);

    final updated = await container
        .read(shipmentNotifierProvider.notifier)
        .acceptBid(shipmentId: '2', bidId: '2');

    expect(updated.status, ShipmentStatus.confirmed);

    final shipments =
        container.read(shipmentNotifierProvider).valueOrNull ?? const [];
    final target = shipments.firstWhere((shipment) => shipment.id == '2');
    expect(target.status, ShipmentStatus.confirmed);
    expect(
      target.bids.where((bid) => bid.status == BidStatus.accepted),
      hasLength(1),
    );
  });
}
