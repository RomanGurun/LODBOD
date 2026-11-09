enum BidStatus {
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  rejected('rejected', 'Rejected');

  const BidStatus(this.wire, this.label);

  final String wire;
  final String label;

  static BidStatus fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return BidStatus.pending;
  }
}
