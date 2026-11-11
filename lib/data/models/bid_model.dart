import 'package:lodbod/domain/entities/bid.dart';
import 'package:lodbod/domain/enums/bid_status.dart';

class BidModel {
  final String id;
  final String shipmentId;
  final String carrierName;
  final double carrierRating;
  final bool carrierVerified;
  final double fare;
  final String currency;
  final int etaDays;
  final DateTime estimatedDeliveryAt;
  final String message;
  final String status;
  final DateTime createdAt;

  const BidModel({
    required this.id,
    required this.shipmentId,
    required this.carrierName,
    required this.carrierRating,
    required this.carrierVerified,
    required this.fare,
    this.currency = 'NPR',
    required this.etaDays,
    required this.estimatedDeliveryAt,
    this.message = '',
    required this.status,
    required this.createdAt,
  });

  factory BidModel.fromEntity(Bid bid) {
    return BidModel(
      id: bid.id,
      shipmentId: bid.shipmentId,
      carrierName: bid.carrierName,
      carrierRating: bid.carrierRating,
      carrierVerified: bid.carrierVerified,
      fare: bid.fare,
      currency: bid.currency,
      etaDays: bid.etaDays,
      estimatedDeliveryAt: bid.estimatedDeliveryAt,
      message: bid.message,
      status: bid.status.wire,
      createdAt: bid.createdAt,
    );
  }

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'].toString(),
      shipmentId: json['shipmentId'].toString(),
      carrierName: json['carrierName'] as String? ?? '',
      carrierRating: (json['carrierRating'] as num?)?.toDouble() ?? 0,
      carrierVerified: json['carrierVerified'] as bool? ?? false,
      fare: (json['fare'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NPR',
      etaDays: (json['etaDays'] as num?)?.toInt() ?? 0,
      estimatedDeliveryAt:
          DateTime.parse(json['estimatedDeliveryAt'] as String),
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? BidStatus.pending.wire,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'shipmentId': shipmentId,
        'carrierName': carrierName,
        'carrierRating': carrierRating,
        'carrierVerified': carrierVerified,
        'fare': fare,
        'currency': currency,
        'etaDays': etaDays,
        'estimatedDeliveryAt': estimatedDeliveryAt.toIso8601String(),
        'message': message,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  Bid toEntity() => Bid(
        id: id,
        shipmentId: shipmentId,
        carrierName: carrierName,
        carrierRating: carrierRating,
        carrierVerified: carrierVerified,
        fare: fare,
        currency: currency,
        etaDays: etaDays,
        estimatedDeliveryAt: estimatedDeliveryAt,
        message: message,
        status: BidStatus.fromWire(status),
        createdAt: createdAt,
      );

  BidModel copyWith({
    String? id,
    String? shipmentId,
    String? carrierName,
    double? carrierRating,
    bool? carrierVerified,
    double? fare,
    String? currency,
    int? etaDays,
    DateTime? estimatedDeliveryAt,
    String? message,
    String? status,
    DateTime? createdAt,
  }) {
    return BidModel(
      id: id ?? this.id,
      shipmentId: shipmentId ?? this.shipmentId,
      carrierName: carrierName ?? this.carrierName,
      carrierRating: carrierRating ?? this.carrierRating,
      carrierVerified: carrierVerified ?? this.carrierVerified,
      fare: fare ?? this.fare,
      currency: currency ?? this.currency,
      etaDays: etaDays ?? this.etaDays,
      estimatedDeliveryAt: estimatedDeliveryAt ?? this.estimatedDeliveryAt,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
