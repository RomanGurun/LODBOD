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
}
