import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

/// Carrier-side status flow after a booking is confirmed.
///
/// In the full product these transitions are made by the carrier once the
/// load is picked up and delivered — the shipper app only observes them.
/// This prototype ships no carrier app, so the shipper app exposes them
/// as clearly-labelled demo controls; this rule gives the UI and the data
/// layer one shared definition of "what comes next".
class ShipmentStatusFlow {
  ShipmentStatusFlow._();

  /// The next status in the lifecycle, or null when [shipment] cannot move
  /// forward (not yet confirmed, already delivered, cancelled or expired).
  static ShipmentStatus? nextStatus(Shipment shipment) {
    return switch (shipment.status) {
      ShipmentStatus.scheduled => ShipmentStatus.inTransit,
      ShipmentStatus.confirmed => ShipmentStatus.inTransit,
      ShipmentStatus.inTransit => ShipmentStatus.delivered,
      _ => null,
    };
  }

  static bool canAdvance(Shipment shipment) => nextStatus(shipment) != null;

  static void ensureCanAdvance(Shipment shipment) {
    if (!canAdvance(shipment)) {
      throw ConflictException(
        'A ${shipment.status.label} shipment cannot be moved forward.',
      );
    }
  }
}
