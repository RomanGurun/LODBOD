import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/shipments/domain/enums/bid_status.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/domain/rules/bid_acceptance_rule.dart';

import '../../../support/fixtures.dart';

void main() {
  group('BidAcceptanceRule.canAccept', () {
    test('allows a pending bid for a shipment awaiting bids', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.awaitingBids,
      );
      final bid = buildBid(shipmentId: shipment.id);

      expect(BidAcceptanceRule.canAccept(shipment, bid), isTrue);
    });

    test('rejects a bid for a different shipment', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.awaitingBids,
      );
      final bid = buildBid(shipmentId: '2');

      expect(BidAcceptanceRule.canAccept(shipment, bid), isFalse);
    });

    test('rejects a bid that is no longer pending', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.awaitingBids,
      );
      final bid = buildBid(
        shipmentId: shipment.id,
        status: BidStatus.rejected,
      );

      expect(BidAcceptanceRule.canAccept(shipment, bid), isFalse);
    });

    test('rejects a bid when the shipment is no longer awaiting bids', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.confirmed,
      );
      final bid = buildBid(shipmentId: shipment.id);

      expect(BidAcceptanceRule.canAccept(shipment, bid), isFalse);
    });

    test('rejects a bid when the shipment already has an accepted bid', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.awaitingBids,
      ).copyWith(acceptedBidId: 'b0');
      final bid = buildBid(shipmentId: shipment.id);

      expect(BidAcceptanceRule.isAlreadyAccepted(shipment), isTrue);
      expect(BidAcceptanceRule.canAccept(shipment, bid), isFalse);
    });
  });

  group('BidAcceptanceRule.ensureCanAccept', () {
    test('passes for a valid acceptance', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.awaitingBids,
      );
      final bid = buildBid(shipmentId: shipment.id);

      expect(
        () => BidAcceptanceRule.ensureCanAccept(shipment, bid),
        returnsNormally,
      );
    });

    test('throws NotFoundException when the bid belongs elsewhere', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.awaitingBids,
      );
      final bid = buildBid(shipmentId: '2');

      expect(
        () => BidAcceptanceRule.ensureCanAccept(shipment, bid),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('throws ConflictException for a processed bid', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.awaitingBids,
      );
      final bid = buildBid(
        shipmentId: shipment.id,
        status: BidStatus.accepted,
      );

      expect(
        () => BidAcceptanceRule.ensureCanAccept(shipment, bid),
        throwsA(isA<ConflictException>()),
      );
    });

    test('throws ConflictException when the shipment is not awaiting bids', () {
      final shipment = buildShipment(
        id: '1',
        status: ShipmentStatus.inTransit,
      );
      final bid = buildBid(shipmentId: shipment.id);

      expect(
        () => BidAcceptanceRule.ensureCanAccept(shipment, bid),
        throwsA(isA<ConflictException>()),
      );
    });
  });
}
