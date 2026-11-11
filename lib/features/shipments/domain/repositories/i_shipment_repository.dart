import 'package:lodbod/features/shipments/domain/entities/bid.dart';
import 'package:lodbod/features/shipments/domain/entities/create_shipment_draft.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

abstract class IShipmentRepository {
  Future<List<Shipment>> getShipments({String? search, ShipmentStatus? status});

  Future<Shipment> getShipmentById(String id);

  Future<List<Bid>> getBids(String shipmentId);

  Future<Shipment> createShipment(CreateShipmentDraft draft);

  Future<Shipment> acceptBid({
    required String shipmentId,
    required String bidId,
  });

  /// Demo control: posts a fictional carrier bid for [shipmentId] to the
  /// data source and returns the updated shipment with its bids.
  ///
  /// There is no carrier app in this prototype, so this stands in for the
  /// carrier side of the marketplace. A shipment that is still `open` is
  /// flipped to `awaiting_bids` so the new bid can be reviewed and
  /// accepted. Shipments that can no longer receive bids (confirmed and
  /// beyond, cancelled, expired) throw a `ConflictException`.
  Future<Shipment> simulateCarrierBid(String shipmentId);

  /// Demo control: advances a shipment to its next lifecycle status
  /// (scheduled/confirmed → in transit, in transit → delivered).
  ///
  /// Shipments that cannot move forward throw a `ConflictException` before
  /// any write happens.
  Future<Shipment> advanceShipmentStatus(String shipmentId);
}
