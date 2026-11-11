import 'package:lodbod/domain/entities/bid.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'package:lodbod/domain/enums/shipment_status.dart';

class ShipmentModel {
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
  final String status;
  final String? acceptedBidId;
  final String? assignedCarrier;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShipmentModel({
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
    required this.createdAt,
    required this.updatedAt,
  });

  static const Object _sentinel = Object();

  factory ShipmentModel.fromEntity(Shipment shipment) {
    return ShipmentModel(
      id: shipment.id,
      reference: shipment.reference,
      shipperName: shipment.shipperName,
      shipperId: shipment.shipperId,
      pickupCity: shipment.pickupCity,
      pickupAddress: shipment.pickupAddress,
      destinationCity: shipment.destinationCity,
      destinationAddress: shipment.destinationAddress,
      cargoDescription: shipment.cargoDescription,
      cargoCategory: shipment.cargoCategory,
      weight: shipment.weight,
      weightUnit: shipment.weightUnit,
      vehicleType: shipment.vehicleType,
      pickupAt: shipment.pickupAt,
      expectedFare: shipment.expectedFare,
      currency: shipment.currency,
      status: shipment.status.wire,
      acceptedBidId: shipment.acceptedBidId,
      assignedCarrier: shipment.assignedCarrier,
      notes: shipment.notes,
      createdAt: shipment.createdAt,
      updatedAt: shipment.updatedAt,
    );
  }

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'].toString(),
      reference: json['reference'] as String? ?? '',
      shipperName: json['shipperName'] as String? ?? '',
      shipperId: _blankToNull(json['shipperId']),
      pickupCity: json['pickupCity'] as String? ?? '',
      pickupAddress: json['pickupAddress'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      destinationAddress: json['destinationAddress'] as String? ?? '',
      cargoDescription: json['cargoDescription'] as String? ?? '',
      cargoCategory: json['cargoCategory'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      weightUnit: json['weightUnit'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      pickupAt: DateTime.parse(json['pickupAt'] as String),
      expectedFare: (json['expectedFare'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NPR',
      status: json['status'] as String? ?? ShipmentStatus.open.wire,
      acceptedBidId: _blankToNull(json['acceptedBidId']),
      assignedCarrier: _blankToNull(json['assignedCarrier']),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'reference': reference,
        'shipperName': shipperName,
        'shipperId': shipperId ?? '',
        'pickupCity': pickupCity,
        'pickupAddress': pickupAddress,
        'destinationCity': destinationCity,
        'destinationAddress': destinationAddress,
        'cargoDescription': cargoDescription,
        'cargoCategory': cargoCategory,
        'weight': weight,
        'weightUnit': weightUnit,
        'vehicleType': vehicleType,
        'pickupAt': pickupAt.toIso8601String(),
        'expectedFare': expectedFare,
        'currency': currency,
        'status': status,
        'acceptedBidId': acceptedBidId ?? '',
        'assignedCarrier': assignedCarrier ?? '',
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Shipment toEntity({List<Bid> bids = const <Bid>[]}) => Shipment(
        id: id,
        reference: reference,
        shipperName: shipperName,
        shipperId: shipperId,
        pickupCity: pickupCity,
        pickupAddress: pickupAddress,
        destinationCity: destinationCity,
        destinationAddress: destinationAddress,
        cargoDescription: cargoDescription,
        cargoCategory: cargoCategory,
        weight: weight,
        weightUnit: weightUnit,
        vehicleType: vehicleType,
        pickupAt: pickupAt,
        expectedFare: expectedFare,
        currency: currency,
        status: ShipmentStatus.fromWire(status),
        acceptedBidId: acceptedBidId,
        assignedCarrier: assignedCarrier,
        notes: notes,
        bids: bids,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ShipmentModel copyWith({
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
    String? status,
    Object? acceptedBidId = _sentinel,
    Object? assignedCarrier = _sentinel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShipmentModel(
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String? _blankToNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
