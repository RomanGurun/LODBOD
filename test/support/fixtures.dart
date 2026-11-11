import 'package:lodbod/features/shipments/domain/entities/bid.dart';
import 'package:lodbod/features/shipments/domain/entities/create_shipment_draft.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/bid_status.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

Shipment buildShipment({
  String id = '1',
  String reference = 'LOD-1001',
  ShipmentStatus status = ShipmentStatus.open,
  DateTime? pickupAt,
  double expectedFare = 18000,
}) {
  final now = DateTime.now();
  return Shipment(
    id: id,
    reference: reference,
    shipperName: 'Demo Shipper',
    pickupCity: 'Kathmandu',
    pickupAddress: 'Kalimati, Kathmandu',
    destinationCity: 'Pokhara',
    destinationAddress: 'Lakeside, Pokhara',
    cargoDescription: 'Steel pipes',
    cargoCategory: 'construction',
    weight: 10,
    weightUnit: 'tonnes',
    vehicleType: 'truck_10w',
    pickupAt: pickupAt ?? now.add(const Duration(days: 5)),
    expectedFare: expectedFare,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

CreateShipmentDraft validDraft({DateTime? now}) {
  final clock = now ?? DateTime.now();
  return CreateShipmentDraft(
    pickupCity: 'Kathmandu',
    pickupAddress: 'Kalimati, Kathmandu',
    destinationCity: 'Pokhara',
    destinationAddress: 'Lakeside, Pokhara',
    cargoDescription: 'Steel pipes',
    cargoCategory: 'construction',
    weight: 10,
    weightUnit: 'tonnes',
    vehicleType: 'truck_10w',
    pickupAt: clock.add(const Duration(days: 5)),
  );
}

Bid buildBid({
  String id = 'b1',
  String shipmentId = '1',
  BidStatus status = BidStatus.pending,
  double fare = 18000,
}) {
  final now = DateTime.now();
  return Bid(
    id: id,
    shipmentId: shipmentId,
    carrierName: 'Himalayan Freight',
    carrierRating: 4.8,
    carrierVerified: true,
    fare: fare,
    etaDays: 2,
    estimatedDeliveryAt: now.add(const Duration(days: 2)),
    message: 'Ready to pick up tomorrow.',
    status: status,
    createdAt: now,
  );
}
