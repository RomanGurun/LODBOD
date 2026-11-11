import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/shared/extensions/num_ext.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';

/// Demo control: posts a fictional carrier bid for [shipment] through the
/// real API (POST /bids, plus a shipment PATCH when the load is still
/// open).
///
/// This prototype ships only the shipper side of the marketplace — there is
/// no carrier app submitting bids — so this button stands in for the
/// carrier side and is labelled as a demo action.
class SimulateBidButton extends ConsumerStatefulWidget {
  const SimulateBidButton({super.key, required this.shipment});

  final Shipment shipment;

  @override
  ConsumerState<SimulateBidButton> createState() => _SimulateBidButtonState();
}

class _SimulateBidButtonState extends ConsumerState<SimulateBidButton> {
  bool _isBusy = false;

  Future<void> _simulate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.simulateBidConfirmTitle),
        content: const Text(AppStrings.simulateBidConfirmMessage),
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

    setState(() => _isBusy = true);
    try {
      final updated = await ref
          .read(shipmentNotifierProvider.notifier)
          .simulateCarrierBid(widget.shipment.id);
      if (!mounted) return;

      // The repository returns the bids newest-first, so the leading bid is
      // the one that was just simulated.
      final newest = updated.bids.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.bidSimulated
                .replaceAll('{carrier}', newest.carrierName)
                .replaceAll('{fare}', newest.fare.toNPR()),
          ),
        ),
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
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : _simulate,
            icon: _isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.local_shipping_outlined, size: 20),
            label: Text(
              _isBusy ? AppStrings.simulating : AppStrings.simulateBid,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Center(
          child: Text(
            AppStrings.demoControlNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ),
      ],
    );
  }
}
