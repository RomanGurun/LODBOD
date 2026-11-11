import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';

/// How many shipments sit in each status, for the breakdown list.
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

/// Shipments created per month over the last [months] months, oldest first.
/// Used by the analytics chart; derived from the shipment list.
final monthlyShipmentCountsProvider =
    Provider.family<AsyncValue<List<(DateTime, int)>>, int>((ref, months) {
  return ref.watch(shipmentNotifierProvider).whenData((shipments) {
    final now = DateTime.now();
    // Month buckets keyed by first day of month, oldest first.
    final buckets = <DateTime, int>{
      for (var i = months - 1; i >= 0; i--)
        DateTime(now.year, now.month - i): 0,
    };

    for (final shipment in shipments) {
      final key = DateTime(
        shipment.createdAt.year,
        shipment.createdAt.month,
      );
      if (buckets.containsKey(key)) {
        buckets[key] = (buckets[key] ?? 0) + 1;
      }
    }

    return buckets.entries
        .map((entry) => (entry.key, entry.value))
        .toList(growable: false);
  });
});
