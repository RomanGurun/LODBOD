import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/domain/entities/bid.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'package:lodbod/domain/enums/shipment_status.dart';

class BidAcceptanceRule {
  BidAcceptanceRule._();

  static bool isAlreadyAccepted(Shipment shipment) {
    return shipment.acceptedBidId != null ||
        shipment.bids.any((bid) => bid.isAccepted);
  }

  static bool canAccept(Shipment shipment, Bid bid) {
    return bid.shipmentId == shipment.id &&
        bid.isPending &&
        shipment.status == ShipmentStatus.awaitingBids &&
        !isAlreadyAccepted(shipment);
  }

  static void ensureCanAccept(Shipment shipment, Bid bid) {
    if (bid.shipmentId != shipment.id) {
      throw const NotFoundException('Bid not found.');
    }
    if (!bid.isPending) {
      throw const ConflictException('This bid has already been processed.');
    }
    if (shipment.status != ShipmentStatus.awaitingBids) {
      throw const ConflictException(
        'This shipment is no longer awaiting bids.',
      );
    }
    if (isAlreadyAccepted(shipment)) {
      throw const ConflictException(
        'This shipment already has an accepted bid.',
      );
    }
  }
}
