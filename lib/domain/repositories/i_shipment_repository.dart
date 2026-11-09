import '../entities/bid.dart';
import '../entities/create_shipment_draft.dart';
import '../entities/shipment.dart';
import '../enums/shipment_status.dart';

abstract class IShipmentRepository {
  Future<List<Shipment>> getShipments({String? search, ShipmentStatus? status});

  Future<Shipment> getShipmentById(String id);

  Future<List<Bid>> getBids(String shipmentId);

  Future<Shipment> createShipment(CreateShipmentDraft draft);

  Future<Shipment> acceptBid({
    required String shipmentId,
    required String bidId,
  });
}
