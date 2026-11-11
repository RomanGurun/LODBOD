import 'package:flutter/material.dart';

import 'package:lodbod/core/constants/app_colors.dart';
import 'package:lodbod/core/constants/app_sizes.dart';
import 'package:lodbod/core/extensions/date_ext.dart';
import 'package:lodbod/core/extensions/num_ext.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'app_card.dart';
import 'dashed_divider.dart';
import 'status_badge.dart';

/// A compact shipment summary card: reference + status badge, route,
/// cargo with pickup date, a dashed divider, and a footer row with the
/// fare on the right.
class ShipmentCard extends StatelessWidget {
  const ShipmentCard({
    super.key,
    required this.shipment,
    this.footerText,
    this.onTap,
  });

  final Shipment shipment;
  final String? footerText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      borderRadius: AppSizes.radiusLg,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                shipment.reference,
                style: textTheme.titleSmall?.copyWith(fontSize: 13),
              ),
              const Spacer(),
              StatusBadge(status: shipment.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            shipment.routeLabel,
            style: textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.inventory_2_outlined,
                size: 13,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${shipment.cargoDescription} •',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                shipment.pickupAt.formatShort(),
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const DashedDivider(),
          const SizedBox(height: 15),
          Row(
            children: <Widget>[
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  footerText ?? shipment.updatedAt.timeAgo(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (shipment.hasExpectedFare)
                Text(
                  shipment.expectedFare.toNPR(),
                  style: textTheme.titleSmall
                      ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
