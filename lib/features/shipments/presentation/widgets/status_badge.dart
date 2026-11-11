import 'package:flutter/material.dart';

import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

Color statusColor(ShipmentStatus status) => _colorsFor(status).$2;

(Color, Color) _colorsFor(ShipmentStatus status) {
  switch (status) {
    case ShipmentStatus.open:
      return (AppColors.statusOpenBg, AppColors.statusOpen);
    case ShipmentStatus.awaitingBids:
      return (AppColors.statusAwaitingBidsBg, AppColors.statusAwaitingBids);
    case ShipmentStatus.scheduled:
      return (AppColors.statusScheduledBg, AppColors.statusScheduled);
    case ShipmentStatus.confirmed:
      return (AppColors.statusConfirmedBg, AppColors.statusConfirmed);
    case ShipmentStatus.inTransit:
      return (AppColors.statusInTransitBg, AppColors.statusInTransit);
    case ShipmentStatus.delivered:
      return (AppColors.statusDeliveredBg, AppColors.statusDelivered);
    case ShipmentStatus.cancelled:
      return (AppColors.statusCancelledBg, AppColors.statusCancelled);
    case ShipmentStatus.expired:
      return (AppColors.surfaceVariant, AppColors.textSecondary);
  }
}
