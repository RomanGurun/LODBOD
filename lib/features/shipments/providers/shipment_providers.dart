import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/bid.dart';
import '../../../domain/entities/shipment.dart';
import '../../../domain/enums/shipment_status.dart';
import 'shipment_notifier.dart';

class ShipmentFilter {
  final String query;
  final ShipmentStatus? status;

  const ShipmentFilter({this.query = '', this.status});

  List<Shipment> apply(List<Shipment> shipments) {
    final normalized = query.trim().toLowerCase();
    return shipments.where((shipment) {
      final matchesStatus = status == null || shipment.status == status;
      final matchesQuery = normalized.isEmpty ||
          shipment.reference.toLowerCase().contains(normalized) ||
          shipment.pickupCity.toLowerCase().contains(normalized) ||
          shipment.destinationCity.toLowerCase().contains(normalized) ||
          shipment.routeLabel.toLowerCase().contains(normalized);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ShipmentFilter &&
            runtimeType == other.runtimeType &&
            query == other.query &&
            status == other.status;
  }

  @override
  int get hashCode => Object.hash(query, status);
}

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

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  return ref
      .watch(shipmentNotifierProvider)
      .whenData(DashboardStats.fromShipments);
});

final shipmentStatusCountsProvider =
    Provider<AsyncValue<Map<ShipmentStatus, int>>>((ref) {
  return ref.watch(shipmentNotifierProvider).whenData((shipments) {
    final counts = <ShipmentStatus, int>{
      for (final status in ShipmentStatus.values) status: 0,
    };
    for (final shipment in shipments) {
      counts[shipment.status] = (counts[shipment.status] ?? 0) + 1;
    }
    return counts;
  });
});

final filteredShipmentsProvider =
    Provider.family<AsyncValue<List<Shipment>>, ShipmentFilter>((ref, filter) {
  return ref.watch(shipmentNotifierProvider).whenData(filter.apply);
});

final shipmentByIdProvider =
    Provider.family<AsyncValue<Shipment?>, String>((ref, id) {
  return ref.watch(shipmentNotifierProvider).whenData((shipments) {
    for (final shipment in shipments) {
      if (shipment.id == id) return shipment;
    }
    return null;
  });
});

final shipmentBidsProvider =
    Provider.family<AsyncValue<List<Bid>>, String>((ref, shipmentId) {
  return ref
      .watch(shipmentByIdProvider(shipmentId))
      .whenData((shipment) => shipment?.bids ?? const <Bid>[]);
});
