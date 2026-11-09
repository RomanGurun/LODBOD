import '../enums/bid_status.dart';

class Bid {
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
  final BidStatus status;
  final DateTime createdAt;

  const Bid({
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

  bool get isPending => status == BidStatus.pending;
  bool get isAccepted => status == BidStatus.accepted;

  Bid copyWith({
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
    BidStatus? status,
    DateTime? createdAt,
  }) {
    return Bid(
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Bid &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            shipmentId == other.shipmentId &&
            carrierName == other.carrierName &&
            carrierRating == other.carrierRating &&
            carrierVerified == other.carrierVerified &&
            fare == other.fare &&
            currency == other.currency &&
            etaDays == other.etaDays &&
            estimatedDeliveryAt == other.estimatedDeliveryAt &&
            message == other.message &&
            status == other.status &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        shipmentId,
        carrierName,
        carrierRating,
        carrierVerified,
        fare,
        currency,
        etaDays,
        estimatedDeliveryAt,
        message,
        status,
        createdAt,
      );

  @override
  String toString() => 'Bid($id, $carrierName, $fare $currency)';
}
