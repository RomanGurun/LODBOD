import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

/// KPI counts derived from a shipper's shipment list.
///
/// Pure domain logic: owned by the dashboard feature and also consumed by
/// analytics (total loads), always computed from the shipment aggregate —
/// never stored separately.
class DashboardStats {
  final int active;
  final int awaitingBids;
  final int completed;
  final int delivered;
  final int total;

  const DashboardStats({
    required this.active,
    required this.awaitingBids,
    required this.completed,
    required this.delivered,
    required this.total,
  });

  factory DashboardStats.fromShipments(Iterable<Shipment> shipments) {
    var active = 0;
    var awaiting = 0;
    var completed = 0;
    var delivered = 0;
    var total = 0;

    for (final shipment in shipments) {
      total++;
      if (shipment.status.countsTowardsLimit) active++;
      if (shipment.status == ShipmentStatus.awaitingBids) awaiting++;
      if (shipment.status.isCompleted) completed++;
      if (shipment.status == ShipmentStatus.delivered) delivered++;
    }

    return DashboardStats(
      active: active,
      awaitingBids: awaiting,
      completed: completed,
      delivered: delivered,
      total: total,
    );
  }
}
