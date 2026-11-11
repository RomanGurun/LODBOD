import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

import 'shipment_notifier.dart';

/// Search + status filter over the shipment list. Pure and testable;
/// applied to the list through [filteredShipmentsProvider].
class ShipmentFilter {
  final String query;
  final ShipmentStatus? status;

  /// When set, only shipments that count towards the active-request limit
  /// (open / awaiting bids / scheduled / confirmed / in transit) are shown.
  final bool activeOnly;

  const ShipmentFilter({
    this.query = '',
    this.status,
    this.activeOnly = false,
  });

  List<Shipment> apply(List<Shipment> shipments) {
    final normalized = query.trim().toLowerCase();
    return shipments.where((shipment) {
      final matchesStatus = status == null || shipment.status == status;
      final matchesActive = !activeOnly || shipment.status.countsTowardsLimit;
      final matchesQuery = normalized.isEmpty ||
          shipment.reference.toLowerCase().contains(normalized) ||
          shipment.pickupCity.toLowerCase().contains(normalized) ||
          shipment.destinationCity.toLowerCase().contains(normalized) ||
          shipment.routeLabel.toLowerCase().contains(normalized);
      return matchesStatus && matchesActive && matchesQuery;
    }).toList();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ShipmentFilter &&
            runtimeType == other.runtimeType &&
            query == other.query &&
            status == other.status &&
            activeOnly == other.activeOnly;
  }

  @override
  int get hashCode => Object.hash(query, status, activeOnly);
}

/// The shipment list narrowed by a [ShipmentFilter], keeping loading,
/// error and empty states explicit through the wrapped [AsyncValue].
final filteredShipmentsProvider =
    Provider.family<AsyncValue<List<Shipment>>, ShipmentFilter>((ref, filter) {
  return ref.watch(shipmentNotifierProvider).whenData(filter.apply);
});

/// One shipment out of the list by repository id, for the detail and
/// tracking screens.
final shipmentByIdProvider =
    Provider.family<AsyncValue<Shipment?>, String>((ref, id) {
  return ref.watch(shipmentNotifierProvider).whenData((shipments) {
    for (final shipment in shipments) {
      if (shipment.id == id) return shipment;
    }
    return null;
  });
});
