import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/shared/extensions/date_ext.dart';
import 'package:lodbod/shared/extensions/num_ext.dart';
import 'package:lodbod/shared/extensions/string_ext.dart';
import 'package:lodbod/features/shipments/domain/entities/bid.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/bid_status.dart';
import 'package:lodbod/features/shipments/domain/rules/bid_acceptance_rule.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';

/// Opens the full bid details bottom sheet: carrier profile, fare, ETA and
/// carrier message, with an explicit confirmation before accepting.
Future<void> showBidDetailsSheet({
  required BuildContext context,
  required Shipment shipment,
  required Bid bid,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BidDetailsSheet(
      shipment: shipment,
      bid: bid,
    ),
  );
}

class BidDetailsSheet extends ConsumerStatefulWidget {
  const BidDetailsSheet({
    super.key,
    required this.shipment,
    required this.bid,
  });

  final Shipment shipment;
  final Bid bid;

  @override
  ConsumerState<BidDetailsSheet> createState() => _BidDetailsSheetState();
}

class _BidDetailsSheetState extends ConsumerState<BidDetailsSheet> {
  bool _isAccepting = false;

  Bid get _bid => widget.bid;
  Shipment get _shipment => widget.shipment;

  /// The same domain rule the repository enforces — one definition of
  /// "this bid can be accepted", shared by UI and data layers.
  bool get _canAccept => BidAcceptanceRule.canAccept(_shipment, _bid);

  Future<void> _accept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.acceptBidConfirmTitle),
        content: Text(
          AppStrings.acceptBidConfirmMessage
              .replaceAll('{carrier}', _bid.carrierName)
              .replaceAll('{fare}', _bid.fare.toNPR()),
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
            shipmentId: _shipment.id,
            bidId: _bid.id,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
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
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetContext, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Carrier header ──
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _bid.carrierName.initials,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _bid.carrierName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_bid.carrierVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.statusOpen,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _bid.carrierVerified
                            ? 'Verified carrier'
                            : 'Not verified',
                        style: textTheme.bodySmall?.copyWith(
                          color: _bid.carrierVerified
                              ? AppColors.statusOpen
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _bid.fare.toNPR(),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // ── Rating comparison context ──
            Text(
              'Bid details · ${_shipment.reference}',
              style: textTheme.labelSmall?.copyWith(
                letterSpacing: 1,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.star,
              label: 'Carrier rating',
              value: '${_bid.carrierRating.toRating()} / 5',
            ),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Delivery time',
              value:
                  '${_bid.etaDays} day${_bid.etaDays == 1 ? '' : 's'}',
            ),
            _DetailRow(
              icon: Icons.event_available,
              label: 'Estimated delivery',
              value: _bid.estimatedDeliveryAt.formatWithTime(),
            ),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Quoted fare',
              value: _bid.fare.toNPR(),
            ),

            if (_bid.message.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carrier message',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${_bid.message.trim()}"',
                      style: textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.gavel_outlined,
              label: 'Bid status',
              value: switch (_bid.status) {
                BidStatus.pending => 'Pending your decision',
                BidStatus.accepted => 'Accepted',
                BidStatus.rejected => 'Not selected',
              },
            ),

            const SizedBox(height: 20),

            // ── Action ──
            SizedBox(
              width: double.infinity,
              child: _canAccept
                  ? FilledButton.icon(
                      onPressed: _isAccepting ? null : _accept,
                      icon: _isAccepting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 20),
                      label: Text(
                        _isAccepting ? 'Accepting…' : AppStrings.acceptBid,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        _bid.isAccepted ? 'This bid was accepted' : 'Close',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
