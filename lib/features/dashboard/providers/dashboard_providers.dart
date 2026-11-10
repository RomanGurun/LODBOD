import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/shipment.dart';
import '../../shipments/providers/shipment_notifier.dart';

/// The most recently updated shipments, for the "Recent shipments" section.
final recentShipmentsProvider = Provider<AsyncValue<List<Shipment>>>((ref) {
  return ref.watch(shipmentNotifierProvider).whenData((shipments) {
    final sorted = List<Shipment>.of(shipments)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(3).toList();
  });
});

/// The awaiting-bids shipment with the most bids, for the action card.
final actionRequiredShipmentProvider = Provider<AsyncValue<Shipment?>>((ref) {
  return ref.watch(shipmentNotifierProvider).whenData((shipments) {
    Shipment? candidate;
    for (final shipment in shipments) {
      if (!shipment.isAwaitingBids || !shipment.hasBids) continue;
      if (candidate == null || shipment.bidCount > candidate.bidCount) {
        candidate = shipment;
      }
    }
    return candidate;
  });
});

/// The shipment with the nearest upcoming pickup window, if any.
final nextPickupShipmentProvider = Provider<AsyncValue<Shipment?>>((ref) {
  return ref.watch(shipmentNotifierProvider).whenData((shipments) {
    final now = DateTime.now();
    Shipment? next;
    for (final shipment in shipments) {
      if (!shipment.pickupAt.isAfter(now)) continue;
      if (next == null || shipment.pickupAt.isBefore(next.pickupAt)) {
        next = shipment;
      }
    }
    return next;
  });
});
