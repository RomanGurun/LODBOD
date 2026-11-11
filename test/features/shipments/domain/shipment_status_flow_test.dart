import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/domain/rules/shipment_status_flow.dart';

import '../../../support/fixtures.dart';

void main() {
  test('advances confirmed and scheduled shipments to in transit', () {
    expect(
      ShipmentStatusFlow.nextStatus(
        buildShipment(status: ShipmentStatus.confirmed),
      ),
      ShipmentStatus.inTransit,
    );
    expect(
      ShipmentStatusFlow.nextStatus(
        buildShipment(status: ShipmentStatus.scheduled),
      ),
      ShipmentStatus.inTransit,
    );
  });

  test('advances in-transit shipments to delivered', () {
    expect(
      ShipmentStatusFlow.nextStatus(
        buildShipment(status: ShipmentStatus.inTransit),
      ),
      ShipmentStatus.delivered,
    );
  });

  test('open shipments can advance only after a bid is accepted', () {
    // An open load first needs bids (and an acceptance) before the
    // carrier-side flow applies.
    expect(
      ShipmentStatusFlow.nextStatus(buildShipment(status: ShipmentStatus.open)),
      isNull,
    );
    expect(
      ShipmentStatusFlow.canAdvance(buildShipment(status: ShipmentStatus.open)),
      isFalse,
    );
  });

  test('terminal and pre-booking statuses have no next status', () {
    for (final status in <ShipmentStatus>[
      ShipmentStatus.awaitingBids,
      ShipmentStatus.delivered,
      ShipmentStatus.cancelled,
      ShipmentStatus.expired,
    ]) {
      expect(
        ShipmentStatusFlow.nextStatus(buildShipment(status: status)),
        isNull,
        reason: '$status should not be advanceable',
      );
      expect(
        ShipmentStatusFlow.canAdvance(buildShipment(status: status)),
        isFalse,
      );
    }
  });

  test('ensureCanAdvance throws for shipments that cannot move forward', () {
    final delivered = buildShipment(status: ShipmentStatus.delivered);
    expect(
      () => ShipmentStatusFlow.ensureCanAdvance(delivered),
      throwsA(isA<ConflictException>()),
    );
  });

  test('ensureCanAdvance passes for advanceable shipments', () {
    final confirmed = buildShipment(status: ShipmentStatus.confirmed);
    ShipmentStatusFlow.ensureCanAdvance(confirmed);
    expect(ShipmentStatusFlow.canAdvance(confirmed), isTrue);
  });

  test('only open and awaiting-bids shipments can receive carrier bids', () {
    for (final status in ShipmentStatus.values) {
      final shipment = buildShipment(status: status);
      final expected = status == ShipmentStatus.open ||
          status == ShipmentStatus.awaitingBids;
      expect(
        shipment.canReceiveBids,
        expected,
        reason: '$status should ${expected ? '' : 'not '}receive bids',
      );
    }
  });

  test('conflict message names the current status', () {
    final shipment = Shipment(
      id: '1',
      reference: 'LOD-1001',
      shipperName: 'Demo Shipper',
      pickupCity: 'Kathmandu',
      pickupAddress: 'Kalimati',
      destinationCity: 'Pokhara',
      destinationAddress: 'Lakeside',
      cargoDescription: 'Steel pipes',
      cargoCategory: 'construction',
      weight: 10,
      weightUnit: 'tonnes',
      vehicleType: 'truck_10w',
      pickupAt: DateTime.now().add(const Duration(days: 2)),
      status: ShipmentStatus.delivered,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(
      () => ShipmentStatusFlow.ensureCanAdvance(shipment),
      throwsA(
        isA<ConflictException>().having(
          (error) => error.message,
          'message',
          contains('Delivered'),
        ),
      ),
    );
  });
}
