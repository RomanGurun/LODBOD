import '../../core/constants/app_strings.dart';

enum ShipmentStatus {
  open('open', AppStrings.statusOpen),
  awaitingBids('awaiting_bids', AppStrings.statusAwaitingBids),
  scheduled('scheduled', AppStrings.statusScheduled),
  confirmed('confirmed', AppStrings.statusConfirmed),
  inTransit('in_transit', AppStrings.statusInTransit),
  delivered('delivered', AppStrings.statusDelivered),
  cancelled('cancelled', AppStrings.statusCancelled),
  expired('expired', AppStrings.statusExpired);

  const ShipmentStatus(this.wire, this.label);

  final String wire;
  final String label;

  static ShipmentStatus fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return ShipmentStatus.open;
  }

  bool get countsTowardsLimit =>
      this == open ||
      this == awaitingBids ||
      this == scheduled ||
      this == confirmed ||
      this == inTransit;

  bool get isCompleted =>
      this == delivered || this == cancelled || this == expired;
}
