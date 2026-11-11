import 'package:flutter/material.dart';

import 'package:lodbod/core/constants/app_colors.dart';
import 'package:lodbod/core/constants/app_sizes.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/extensions/date_ext.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'package:lodbod/shared/widgets/app_card.dart';

/// Compact row for the shipment with the nearest upcoming pickup,
/// with a plain "Details" text action on the right.
class DashboardNextPickupCard extends StatelessWidget {
  const DashboardNextPickupCard({
    super.key,
    required this.shipment,
    required this.onDetails,
  });

  final Shipment shipment;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onDetails,
      borderRadius: AppSizes.radiusLg,
      padding: const EdgeInsets.fromLTRB(15, 0, 8, 0),
      child: SizedBox(
        height: 70,
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${AppStrings.nextPickup} • ${shipment.reference}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shipment.routeLabel} • '
                    '${shipment.pickupAt.formatShortWithTime()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onDetails,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(64, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppStrings.details,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
