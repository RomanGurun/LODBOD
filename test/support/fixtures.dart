import 'package:lodbod/domain/entities/create_shipment_draft.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'package:lodbod/domain/enums/shipment_status.dart';

Shipment buildShipment({
  String id = '1',
  String reference = 'LOD-1001',
  ShipmentStatus status = ShipmentStatus.open,
  DateTime? pickupAt,
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
    expectedFare: 18000,
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
