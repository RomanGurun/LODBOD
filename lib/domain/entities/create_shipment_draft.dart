class CreateShipmentDraft {
  final String pickupCity;
  final String pickupAddress;
  final String destinationCity;
  final String destinationAddress;
  final String cargoDescription;
  final String cargoCategory;
  final double weight;
  final String weightUnit;
  final String vehicleType;
  final DateTime pickupAt;
  final double expectedFare;
  final String currency;
  final String notes;

  /// Authenticated shipper's Firebase UID. Stamped by the application layer
  /// before submission so every created shipment records its owner.
  final String? shipperId;

  /// Display name of the shipper that created the shipment.
  final String shipperName;

  const CreateShipmentDraft({
    required this.pickupCity,
    required this.pickupAddress,
    required this.destinationCity,
    required this.destinationAddress,
    required this.cargoDescription,
    required this.cargoCategory,
    required this.weight,
    required this.weightUnit,
    required this.vehicleType,
    required this.pickupAt,
    this.expectedFare = 0,
    this.currency = 'NPR',
    this.notes = '',
    this.shipperId,
    this.shipperName = 'Demo Shipper',
  });

  /// Returns a copy stamped with the owning shipper's identity.
  CreateShipmentDraft ownedBy({required String uid, required String name}) {
    return copyWith(shipperId: uid, shipperName: name);
  }

  CreateShipmentDraft copyWith({
    String? pickupCity,
    String? pickupAddress,
    String? destinationCity,
    String? destinationAddress,
    String? cargoDescription,
    String? cargoCategory,
    double? weight,
    String? weightUnit,
    String? vehicleType,
    DateTime? pickupAt,
    double? expectedFare,
    String? currency,
    String? notes,
    String? shipperId,
    String? shipperName,
  }) {
    return CreateShipmentDraft(
      pickupCity: pickupCity ?? this.pickupCity,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      cargoCategory: cargoCategory ?? this.cargoCategory,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      vehicleType: vehicleType ?? this.vehicleType,
      pickupAt: pickupAt ?? this.pickupAt,
      expectedFare: expectedFare ?? this.expectedFare,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      shipperId: shipperId ?? this.shipperId,
      shipperName: shipperName ?? this.shipperName,
    );
  }
}
