import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/date_ext.dart';
import '../../../core/extensions/num_ext.dart';
import '../../../core/extensions/string_ext.dart';
import '../../../domain/entities/bid.dart';
import '../../../domain/entities/shipment.dart';
import '../../../domain/enums/bid_status.dart';
import '../../../domain/enums/shipment_status.dart';
import '../../shipments/providers/shipment_notifier.dart';

class BidCard extends ConsumerStatefulWidget {
  const BidCard({super.key, required this.shipment, required this.bid});

  final Shipment shipment;
  final Bid bid;

  @override
  ConsumerState<BidCard> createState() => _BidCardState();
}

class _BidCardState extends ConsumerState<BidCard> {
  bool _isAccepting = false;

  bool get _canAccept =>
      widget.shipment.status == ShipmentStatus.awaitingBids &&
      widget.bid.status == BidStatus.pending;

  Future<void> _accept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.acceptBidConfirmTitle),
        content: Text(
          AppStrings.acceptBidConfirmMessage
              .replaceAll('{carrier}', widget.bid.carrierName)
              .replaceAll('{fare}', widget.bid.fare.toNPR()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isAccepting = true);
    try {
      await ref.read(shipmentNotifierProvider.notifier).acceptBid(
            shipmentId: widget.shipment.id,
            bidId: widget.bid.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.bidAccepted)),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.genericError)),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: bid.isAccepted
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
      ),
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
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
                          bid.carrierRating.toRating(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                bid.fare.toNPR(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          if (bid.message.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              '"${bid.message.trim()}"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              _BidStatusChip(status: bid.status),
              const Spacer(),
              if (_canAccept)
                FilledButton.tonal(
                  onPressed: _isAccepting ? null : _accept,
                  child: _isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.acceptBid),
                )
              else if (bid.isAccepted)
                Text(
                  'Accepted',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                )
              else if (bid.status == BidStatus.rejected)
                Text(
                  'Not selected',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ],
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
