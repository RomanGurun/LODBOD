import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/domain/rules/shipment_status_flow.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';

/// Demo control: advances [shipment] to its next lifecycle status
/// (confirmed/scheduled → in transit → delivered) through the real API
/// (PATCH /shipments).
///
/// In the full product the carrier makes these updates after pickup and
/// delivery; this prototype has no carrier app, so the button stands in
/// for that side and is labelled as a demo action. Renders nothing when
/// the shipment cannot move forward.
class AdvanceStatusButton extends ConsumerStatefulWidget {
  const AdvanceStatusButton({super.key, required this.shipment});

  final Shipment shipment;

  @override
  ConsumerState<AdvanceStatusButton> createState() =>
      _AdvanceStatusButtonState();
}

class _AdvanceStatusButtonState extends ConsumerState<AdvanceStatusButton> {
  bool _isBusy = false;

  Future<void> _advance() async {
    final shipment = widget.shipment;
    final next = ShipmentStatusFlow.nextStatus(shipment);
    if (next == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.advanceStatusConfirmTitle),
        content: Text(
          AppStrings.advanceStatusConfirmMessage
              .replaceAll('{reference}', shipment.reference)
              .replaceAll('{status}', next.label),
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

    setState(() => _isBusy = true);
    try {
      final updated = await ref
          .read(shipmentNotifierProvider.notifier)
          .advanceShipmentStatus(shipment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.statusAdvanced
                .replaceAll('{reference}', updated.reference)
                .replaceAll('{status}', updated.status.label),
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
    final next = ShipmentStatusFlow.nextStatus(widget.shipment);
    if (next == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : _advance,
            icon: _isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    next == ShipmentStatus.inTransit
                        ? Icons.local_shipping_outlined
                        : Icons.task_alt_outlined,
                    size: 20,
                  ),
            label: Text(
              _isBusy
                  ? AppStrings.advancing
                  : AppStrings.advanceStatusButton
                      .replaceAll('{status}', next.label),
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
