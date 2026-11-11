import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/shipments/domain/enums/bid_status.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/domain/rules/shipment_limit_rule.dart';

import '../../../support/fixtures.dart';

void main() {
  late MockShipmentRepository repository;

  setUp(() {
    repository = MockShipmentRepository(latency: Duration.zero);
  });

  test('loads seed data with two active shipments', () async {
    final shipments = await repository.getShipments();

    expect(shipments, hasLength(4));
    expect(ShipmentLimitRule.countActive(shipments), 2);
  });

  test('LOD-1002 exposes two pending bids', () async {
    final shipment = await repository.getShipmentById('2');

    expect(shipment.reference, 'LOD-1002');
    expect(shipment.status, ShipmentStatus.awaitingBids);
    expect(shipment.bids, hasLength(2));
    expect(
      shipment.bids.every((bid) => bid.status == BidStatus.pending),
      isTrue,
    );
  });

  test('search matches reference, route, or city', () async {
    expect(
      (await repository.getShipments(search: 'LOD-1002')).single.reference,
      'LOD-1002',
    );
    expect(
      (await repository.getShipments(search: 'birgunj')).single.reference,
      'LOD-1002',
    );
    expect(
      (await repository.getShipments(search: 'pokhara')).single.reference,
      'LOD-1001',
    );
  });

  test('filters shipments by status', () async {
    final delivered =
        await repository.getShipments(status: ShipmentStatus.delivered);

    expect(delivered.single.reference, 'LOD-1003');
  });

  test('create appends a shipment with the next reference', () async {
    final created = await repository.createShipment(validDraft());

    expect(created.reference, 'LOD-1005');
    expect(created.status, ShipmentStatus.open);
    expect(created.countsTowardsLimit, isTrue);

    final shipments = await repository.getShipments();
    expect(shipments, hasLength(5));
  });

  test('acceptBid confirms the shipment and rejects competing bids', () async {
    final before = await repository.getShipmentById('2');
    final lowest = before.bids.reduce(
      (a, b) => a.fare <= b.fare ? a : b,
    );

    final updated = await repository.acceptBid(
      shipmentId: '2',
      bidId: lowest.id,
    );

    expect(updated.status, ShipmentStatus.confirmed);
    expect(updated.assignedCarrier, lowest.carrierName);
    expect(updated.acceptedBidId, lowest.id);
    expect(
      updated.bids.where((bid) => bid.status == BidStatus.accepted),
      hasLength(1),
    );
    expect(
      updated.bids.where((bid) => bid.status == BidStatus.rejected),
      hasLength(1),
    );
  });

  test('read failures surface as NetworkException', () async {
    final failing =
        MockShipmentRepository(latency: Duration.zero, failReads: true);

    await expectLater(
      failing.getShipments(),
      throwsA(isA<NetworkException>()),
    );
  });

  test('write failures surface as ServerException without mutating data',
      () async {
    final failing =
        MockShipmentRepository(latency: Duration.zero, failWrites: true);

    await expectLater(
      failing.createShipment(validDraft()),
      throwsA(isA<ServerException>()),
    );

    final shipments = await failing.getShipments();
    expect(shipments, hasLength(4));
  });

  test('simulateCarrierBid adds a third pending bid to LOD-1002', () async {
    final updated = await repository.simulateCarrierBid('2');

    expect(updated.status, ShipmentStatus.awaitingBids);
    expect(updated.bidCount, 3);
    final newBid = updated.bids.first;
    expect(newBid.status, BidStatus.pending);
    expect(newBid.carrierName, isNotEmpty);
    expect(newBid.fare, greaterThan(0));
    expect(newBid.etaDays, inInclusiveRange(1, 4));

    // The bid is persisted: a fresh read sees it too.
    final reloaded = await repository.getShipmentById('2');
    expect(reloaded.bidCount, 3);
  });

  test('simulateCarrierBid flips a newly posted open load to awaiting bids',
      () async {
    final created = await repository.createShipment(validDraft());
    expect(created.status, ShipmentStatus.open);
    expect(created.canReceiveBids, isTrue);

    final updated = await repository.simulateCarrierBid(created.id);

    expect(updated.status, ShipmentStatus.awaitingBids);
    expect(updated.bidCount, 1);
    expect(updated.bids.single.shipmentId, created.id);
    expect(updated.bids.single.status, BidStatus.pending);
  });

  test('simulateCarrierBid refuses shipments that cannot receive bids',
      () async {
    await expectLater(
      repository.simulateCarrierBid('3'), // LOD-1003 is delivered
      throwsA(isA<ConflictException>()),
    );

    // Nothing was written: still just the two seeded bids.
    final shipments = await repository.getShipments();
    expect(shipments, hasLength(4));
    expect((await repository.getBids('3')), isEmpty);
  });

  test('advanceShipmentStatus walks confirmed to delivered in two steps',
      () async {
    // Accept a bid on LOD-1002 first, so the shipment is confirmed.
    await repository.acceptBid(shipmentId: '2', bidId: '2');

    final inTransit = await repository.advanceShipmentStatus('2');
    expect(inTransit.status, ShipmentStatus.inTransit);
    expect(inTransit.assignedCarrier, 'Swift Transport');

    final delivered = await repository.advanceShipmentStatus('2');
    expect(delivered.status, ShipmentStatus.delivered);
    // The accepted bid is still attached to the booking.
    expect(delivered.bidCount, 2);
    expect(
      delivered.bids.where((bid) => bid.status == BidStatus.accepted),
      hasLength(1),
    );
  });

  test('advanceShipmentStatus refuses terminal shipments', () async {
    await expectLater(
      repository.advanceShipmentStatus('3'), // delivered seed
      throwsA(isA<ConflictException>()),
    );
    await expectLater(
      repository.advanceShipmentStatus('2'), // still awaiting bids
      throwsA(isA<ConflictException>()),
    );

    // A refused advance leaves the status untouched.
    final unchanged = await repository.getShipmentById('2');
    expect(unchanged.status, ShipmentStatus.awaitingBids);
  });
}
