import 'package:lodbod/features/shipments/domain/entities/shipment.dart';

/// Shipment ownership rules.
///
/// The public MockAPI has no authentication, so ownership is enforced
/// client-side: every shipment created through the app is stamped with the
/// authenticated Firebase UID in [Shipment.shipperId], and only shipments
/// owned by the signed-in shipper are listed or can be managed.
///
/// The seeded sample records (LOD-1001 … LOD-1004) predate `shipperId` and
/// belong to no real Firebase user. They are mapped to a single explicit
/// demo owner ([demoOwnerUid]) so the demo journey works, and they are never
/// exposed to other users just because their `shipperName` is "Demo Shipper".
///
/// This is a prototype-only authorization: a public API cannot provide
/// production-grade ownership, so a real backend must scope reads and writes
/// by the authenticated caller server-side.
class ShipmentOwnership {
  ShipmentOwnership._();

  /// UID of the local demo account that owns the seeded sample records.
  static const String demoOwnerUid = 'demo-1';

  /// Whether [uid] may see and manage [shipment].
  static bool isOwnedBy(Shipment shipment, String uid) {
    final shipperId = shipment.shipperId?.trim() ?? '';
    if (shipperId.isNotEmpty) return shipperId == uid;
    // Legacy seeded records without a shipperId map to the demo owner only.
    return uid == demoOwnerUid;
  }

  /// Filters [shipments] down to those owned by [uid].
  static List<Shipment> ownedBy(Iterable<Shipment> shipments, String uid) {
    return shipments
        .where((shipment) => isOwnedBy(shipment, uid))
        .toList();
  }
}
