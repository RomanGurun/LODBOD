import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/date_ext.dart';
import '../../../core/extensions/num_ext.dart';
import '../../../core/extensions/string_ext.dart';
import '../../../domain/entities/bid.dart';
import '../../../domain/entities/shipment.dart';
import '../../../domain/enums/bid_status.dart';
import 'bid_details_sheet.dart';

/// Compact carrier bid summary card. Tapping it opens the full bid details
/// sheet where the bid can be compared and accepted.
class BidCard extends StatelessWidget {
  const BidCard({super.key, required this.shipment, required this.bid});

  final Shipment shipment;
  final Bid bid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: bid.isAccepted
            ? Border.all(color: AppColors.success, width: 1.5)
            : Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: () => showBidDetailsSheet(
            context: context,
            shipment: shipment,
            bid: bid,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: AppSizes.avatarSm / 2,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        bid.carrierName.initials,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  bid.carrierName,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (bid.carrierVerified) ...[
                                const SizedBox(width: AppSizes.xs),
                                const Icon(
                                  Icons.verified,
                                  size: AppSizes.iconSm,
                                  color: AppColors.statusOpen,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: AppSizes.iconSm,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: AppSizes.xs),
                              Text(
                                '${bid.carrierRating.toRating()} / 5',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bid.fare.toNPR(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _BidStatusChip(status: bid.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: AppSizes.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        '${bid.etaDays} day${bid.etaDays == 1 ? '' : 's'} \u00b7 '
                        'ETA ${bid.estimatedDeliveryAt.formatDisplay()}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: AppSizes.iconSm,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
                if (bid.message.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    '"${bid.message.trim()}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BidStatusChip extends StatelessWidget {
  const _BidStatusChip({required this.status});

  final BidStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      BidStatus.pending => (
          AppColors.statusAwaitingBidsBg,
          AppColors.statusAwaitingBids,
        ),
      BidStatus.accepted => (
          AppColors.statusConfirmedBg,
          AppColors.statusConfirmed,
        ),
      BidStatus.rejected => (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
        ),
    };

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
