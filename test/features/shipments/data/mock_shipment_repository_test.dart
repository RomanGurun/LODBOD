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
}
