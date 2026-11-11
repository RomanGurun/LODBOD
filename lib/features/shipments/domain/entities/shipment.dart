import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/domain/entities/bid.dart';

class Shipment {
  final String id;
  final String reference;
  final String shipperName;
  final String? shipperId;
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
  final ShipmentStatus status;
  final String? acceptedBidId;
  final String? assignedCarrier;
  final String notes;
  final List<Bid> bids;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shipment({
    required this.id,
    required this.reference,
    required this.shipperName,
    this.shipperId,
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
    required this.status,
    this.acceptedBidId,
    this.assignedCarrier,
    this.notes = '',
    this.bids = const <Bid>[],
    required this.createdAt,
    required this.updatedAt,
  });

  static const Object _sentinel = Object();

  int get bidCount => bids.length;

  bool get hasBids => bids.isNotEmpty;

  bool get hasExpectedFare => expectedFare > 0;

  bool get isAwaitingBids => status == ShipmentStatus.awaitingBids;

  /// Whether carriers can still submit bids on this shipment: true while
  /// the load is posted (open) or actively awaiting bids.
  bool get canReceiveBids =>
      status == ShipmentStatus.open || status == ShipmentStatus.awaitingBids;

  bool get countsTowardsLimit => status.countsTowardsLimit;

  String get routeLabel => '$pickupCity \u2192 $destinationCity';

  Bid? get acceptedBid {
    final id = acceptedBidId;
    if (id == null) return null;
    for (final bid in bids) {
      if (bid.id == id) return bid;
    }
    return null;
  }

  Shipment copyWith({
    String? id,
    String? reference,
    String? shipperName,
    Object? shipperId = _sentinel,
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
    ShipmentStatus? status,
    Object? acceptedBidId = _sentinel,
    Object? assignedCarrier = _sentinel,
    String? notes,
    List<Bid>? bids,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shipment(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      shipperName: shipperName ?? this.shipperName,
      shipperId: identical(shipperId, _sentinel)
          ? this.shipperId
          : shipperId as String?,
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
      status: status ?? this.status,
      acceptedBidId: identical(acceptedBidId, _sentinel)
          ? this.acceptedBidId
          : acceptedBidId as String?,
      assignedCarrier: identical(assignedCarrier, _sentinel)
          ? this.assignedCarrier
          : assignedCarrier as String?,
      notes: notes ?? this.notes,
      bids: bids ?? this.bids,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Shipment &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            reference == other.reference &&
            shipperName == other.shipperName &&
            shipperId == other.shipperId &&
            pickupCity == other.pickupCity &&
            pickupAddress == other.pickupAddress &&
            destinationCity == other.destinationCity &&
            destinationAddress == other.destinationAddress &&
            cargoDescription == other.cargoDescription &&
            cargoCategory == other.cargoCategory &&
            weight == other.weight &&
            weightUnit == other.weightUnit &&
            vehicleType == other.vehicleType &&
            pickupAt == other.pickupAt &&
            expectedFare == other.expectedFare &&
            currency == other.currency &&
            status == other.status &&
            acceptedBidId == other.acceptedBidId &&
            assignedCarrier == other.assignedCarrier &&
            notes == other.notes &&
            _listEquals(bids, other.bids) &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        reference,
        shipperName,
        shipperId,
        pickupCity,
        pickupAddress,
        destinationCity,
        destinationAddress,
        cargoDescription,
        cargoCategory,
        weight,
        weightUnit,
        vehicleType,
        pickupAt,
        expectedFare,
        currency,
        status,
        acceptedBidId,
        assignedCarrier,
        notes,
        Object.hashAll(bids),
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() => 'Shipment($reference, $routeLabel, ${status.wire})';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
