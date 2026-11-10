import '../models/bid_model.dart';
import '../models/shipment_model.dart';

List<ShipmentModel> buildSeedShipments({DateTime? now}) {
  final clock = now ?? DateTime.now();

  DateTime future(int addDays, {int hour = 8}) =>
      DateTime(clock.year, clock.month, clock.day + addDays, hour);
  DateTime past(int subDays, {int hour = 10}) =>
      DateTime(clock.year, clock.month, clock.day - subDays, hour);

  return <ShipmentModel>[
    ShipmentModel(
      id: '1',
      reference: 'LOD-1001',
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
      pickupAt: past(1),
      expectedFare: 18000,
      status: 'in_transit',
      assignedCarrier: 'Everest Freight',
      createdAt: past(8),
      updatedAt: clock.subtract(const Duration(minutes: 2)),
    ),
    ShipmentModel(
      id: '2',
      reference: 'LOD-1002',
      shipperName: 'Demo Shipper',
      pickupCity: 'Birgunj',
      pickupAddress: 'Dry Port, Birgunj',
      destinationCity: 'Kathmandu',
      destinationAddress: 'Kalimati, Kathmandu',
      cargoDescription: 'Cement bags',
      cargoCategory: 'construction',
      weight: 12,
      weightUnit: 'tonnes',
      vehicleType: 'truck_10w',
      pickupAt: future(3),
      status: 'awaiting_bids',
      notes: 'Handle with care',
      createdAt: past(7),
      updatedAt: past(7),
    ),
    ShipmentModel(
      id: '3',
      reference: 'LOD-1003',
      shipperName: 'Demo Shipper',
      pickupCity: 'Butwal',
      pickupAddress: 'Traffic Chowk, Butwal',
      destinationCity: 'Narayanghat',
      destinationAddress: 'Pulchowk, Narayanghat',
      cargoDescription: 'Rice sacks',
      cargoCategory: 'agriculture',
      weight: 8,
      weightUnit: 'tonnes',
      vehicleType: 'truck_6w',
      pickupAt: past(15),
      expectedFare: 12500,
      status: 'delivered',
      assignedCarrier: 'Terai Logistics',
      createdAt: past(20),
      updatedAt: past(14),
    ),
    ShipmentModel(
      id: '4',
      reference: 'LOD-1004',
      shipperName: 'Demo Shipper',
      pickupCity: 'Kathmandu',
      pickupAddress: 'Balaju, Kathmandu',
      destinationCity: 'Biratnagar',
      destinationAddress: 'Main Road, Biratnagar',
      cargoDescription: 'Furniture',
      cargoCategory: 'household',
      weight: 4,
      weightUnit: 'tonnes',
      vehicleType: 'truck_6w',
      pickupAt: future(1, hour: 7),
      expectedFare: 24000,
      status: 'cancelled',
      notes: 'Cancelled by shipper',
      createdAt: past(5),
      updatedAt: past(4),
    ),
  ];
}

List<BidModel> buildSeedBids({DateTime? now}) {
  final clock = now ?? DateTime.now();

  DateTime future(int addDays, {int hour = 8}) =>
      DateTime(clock.year, clock.month, clock.day + addDays, hour);
  DateTime past(int subDays, {int hour = 10}) =>
      DateTime(clock.year, clock.month, clock.day - subDays, hour);

  return <BidModel>[
    BidModel(
      id: '1',
      shipmentId: '2',
      carrierName: 'Himalayan Cargo',
      carrierRating: 4.6,
      carrierVerified: true,
      fare: 32000,
      etaDays: 2,
      estimatedDeliveryAt: future(14, hour: 18),
      message: 'Can pick up same day',
      status: 'pending',
      createdAt: past(6, hour: 12),
    ),
    BidModel(
      id: '2',
      shipmentId: '2',
      carrierName: 'Swift Transport',
      carrierRating: 4.1,
      carrierVerified: true,
      fare: 29500,
      etaDays: 3,
      estimatedDeliveryAt: future(15, hour: 18),
      status: 'pending',
      createdAt: past(6, hour: 13),
    ),
    BidModel(
      id: '3',
      shipmentId: '2',
      carrierName: 'Sagarmatha Logistics',
      carrierRating: 4.4,
      carrierVerified: true,
      fare: 30500,
      etaDays: 2,
      estimatedDeliveryAt: future(14, hour: 18),
      status: 'pending',
      createdAt: past(6, hour: 14),
    ),
  ];
}
