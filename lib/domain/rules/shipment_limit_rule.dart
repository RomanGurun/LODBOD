import '../../core/errors/app_exception.dart';
import '../entities/shipment.dart';

class ShipmentLimitRule {
  ShipmentLimitRule._();

  static const int maxActiveShipments = 3;

  static int countActive(Iterable<Shipment> shipments) =>
      shipments.where((shipment) => shipment.countsTowardsLimit).length;

  static bool isAtLimit(Iterable<Shipment> shipments) =>
      countActive(shipments) >= maxActiveShipments;

  static void ensureCanCreate(Iterable<Shipment> shipments) {
    if (isAtLimit(shipments)) {
      throw const LimitException();
    }
  }
}
