import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/shipments/data/mock/seed_data.dart';
import 'package:lodbod/features/shipments/data/models/shipment_model.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/shipments/domain/enums/bid_status.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';
import 'package:lodbod/core/di/repository_providers.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fixtures.dart';

void main() {
  ProviderContainer containerWith(
    MockShipmentRepository repository, {
    AuthUser? user,
  }) {
    final container = ProviderContainer(
      overrides: <Override>[
        shipmentRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('build loads only the shipments owned by the signed-in shipper',
      () async {
    // A signed-out shipper sees nothing.
    final anonymous = ProviderContainer(
      overrides: <Override>[
        shipmentRepositoryProvider.overrideWithValue(
          MockShipmentRepository(latency: Duration.zero),
        ),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository.signedOut(),
        ),
      ],
    );
    addTearDown(anonymous.dispose);
    expect(await anonymous.read(shipmentNotifierProvider.future), isEmpty);

    // The demo owner owns the seeded records (legacy shipperId mapping).
    final container =
        containerWith(MockShipmentRepository(latency: Duration.zero));
    final shipments = await container.read(shipmentNotifierProvider.future);
    expect(shipments, hasLength(4));
  });

  test('build hides shipments belonging to another shipper', () async {
    final otherShipper = ShipmentModel(
      id: 'other-1',
      reference: 'LOD-9001',
      shipperName: 'Someone Else',
      shipperId: 'user-other',
      pickupCity: 'Kathmandu',
      pickupAddress: 'Kalimati',
      destinationCity: 'Pokhara',
      destinationAddress: 'Lakeside',
      cargoDescription: 'Tiles',
      cargoCategory: 'construction',
      weight: 5,
      weightUnit: 'tonnes',
      vehicleType: 'truck_10w',
      pickupAt: DateTime.now().add(const Duration(days: 2)),
      expectedFare: 9000,
      status: 'awaiting_bids',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final repository = MockShipmentRepository(
      shipments: <ShipmentModel>[
        ...buildSeedShipments(),
        otherShipper,
      ],
      bids: const [],
      latency: Duration.zero,
    );
    final container = containerWith(repository);

    final shipments = await container.read(shipmentNotifierProvider.future);

    expect(shipments, hasLength(4));
    expect(
      shipments.where((s) => s.reference == 'LOD-9001'),
      isEmpty,
    );
  });

  test('a different shipper never sees the seeded demo records', () async {
    final container = containerWith(
      MockShipmentRepository(latency: Duration.zero),
      user: const AuthUser(
        id: 'someone-else',
        email: 'someone@else.com',
        displayName: 'Someone Else',
      ),
    );

    final shipments = await container.read(shipmentNotifierProvider.future);

    expect(shipments, isEmpty);
  });

  test('createShipment stamps the owner and appends the created shipment',
      () async {
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
    expect(created.shipperId, 'demo-1');
    expect(created.shipperName, 'Aarav Shrestha');
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

  test('acceptBid rejects a shipment owned by another shipper', () async {
    final container = containerWith(
      MockShipmentRepository(latency: Duration.zero),
      user: const AuthUser(
        id: 'someone-else',
        email: 'someone@else.com',
        displayName: 'Someone Else',
      ),
    );
    // Foreign shipments never enter this user's list, so they cannot be
    // addressed at all — the notifier refuses before contacting the API.
    await container.read(shipmentNotifierProvider.future);

    await expectLater(
      container
          .read(shipmentNotifierProvider.notifier)
          .acceptBid(shipmentId: '2', bidId: '1'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('simulateCarrierBid turns an open load into an awaiting-bids one',
      () async {
    final container =
        containerWith(MockShipmentRepository(latency: Duration.zero));
    await container.read(shipmentNotifierProvider.future);

    final created = await container
        .read(shipmentNotifierProvider.notifier)
        .createShipment(validDraft());
    expect(created.status, ShipmentStatus.open);

    final updated = await container
        .read(shipmentNotifierProvider.notifier)
        .simulateCarrierBid(created.id);

    expect(updated.status, ShipmentStatus.awaitingBids);
    expect(updated.bidCount, 1);
    expect(updated.bids.single.status, BidStatus.pending);

    // The state list reflects the simulated bid without a refresh.
    final shipments =
        container.read(shipmentNotifierProvider).valueOrNull ?? const [];
    final target = shipments.firstWhere((s) => s.id == created.id);
    expect(target.status, ShipmentStatus.awaitingBids);
    expect(target.bidCount, 1);
  });

  test('advanceShipmentStatus walks the state to delivered', () async {
    final container =
        containerWith(MockShipmentRepository(latency: Duration.zero));
    await container.read(shipmentNotifierProvider.future);

    final confirmed =
        await container.read(shipmentNotifierProvider.notifier).acceptBid(
              shipmentId: '2',
              bidId: '2',
            );

    final inTransit = await container
        .read(shipmentNotifierProvider.notifier)
        .advanceShipmentStatus('2');
    expect(inTransit.status, ShipmentStatus.inTransit);

    final delivered = await container
        .read(shipmentNotifierProvider.notifier)
        .advanceShipmentStatus('2');
    expect(delivered.status, ShipmentStatus.delivered);

    final shipments =
        container.read(shipmentNotifierProvider).valueOrNull ?? const [];
    expect(
      shipments.firstWhere((s) => s.id == '2').status,
      ShipmentStatus.delivered,
    );
    expect(confirmed.status, ShipmentStatus.confirmed);
  });

  test('demo actions never touch another shipper or missing shipments',
      () async {
    final container = containerWith(
      MockShipmentRepository(latency: Duration.zero),
      user: const AuthUser(
        id: 'someone-else',
        email: 'someone@else.com',
        displayName: 'Someone Else',
      ),
    );
    await container.read(shipmentNotifierProvider.future);

    // Foreign shipments are not in this user's list → not found, no write.
    await expectLater(
      container.read(shipmentNotifierProvider.notifier).simulateCarrierBid('2'),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      container
          .read(shipmentNotifierProvider.notifier)
          .advanceShipmentStatus('2'),
      throwsA(isA<NotFoundException>()),
    );
  });
}
