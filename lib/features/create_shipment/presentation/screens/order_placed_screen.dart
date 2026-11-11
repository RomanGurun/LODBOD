import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/shared/extensions/date_ext.dart';
import 'package:lodbod/shared/extensions/num_ext.dart';
import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/vehicle_type.dart';

/// Full-screen success confirmation shown after placing a load order.
///
/// Shown only after the repository confirmed the shipment was persisted —
/// a failed submission never reaches this screen.
class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({
    super.key,
    this.reference = 'LOD-XXXX',
    this.route = '—',
    this.cargo = '—',
    this.vehicle = '—',
    this.pickupDate = '—',
  });

  factory OrderPlacedScreen.fromShipment(Shipment shipment) {
    return OrderPlacedScreen(
      reference: shipment.reference,
      route: shipment.routeLabel,
      cargo:
          '${shipment.cargoDescription} · ${shipment.weight.toWeight(shipment.weightUnit)}',
      vehicle: VehicleType.fromWire(shipment.vehicleType).label,
      pickupDate: shipment.pickupAt.formatWithTime(),
    );
  }

  final String reference;
  final String route;
  final String cargo;
  final String vehicle;
  final String pickupDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Scrollable so the confirmation stays fully visible on short
      // viewports (small phones, landscape, large text scale).
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Orange-to-white gradient header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 60,
                bottom: 40,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primarySoft,
                    AppColors.screen,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Checkmark circle — 87x87
                  Container(
                    width: AppSizes.successLogo,
                    height: AppSizes.successLogo,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.textOnPrimary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Order placed',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your load request $reference has been\nsubmitted successfully.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Request summary table ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHorizontal,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request summary',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(label: 'Reference', value: reference),
                    const SizedBox(height: 12),
                    _SummaryRow(label: 'Route', value: route),
                    const SizedBox(height: 12),
                    _SummaryRow(label: 'Cargo', value: cargo),
                    const SizedBox(height: 12),
                    _SummaryRow(label: 'Vehicle', value: vehicle),
                    const SizedBox(height: 12),
                    _SummaryRow(label: 'Pickup date', value: pickupDate),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Bottom buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenHorizontal,
                0,
                AppSizes.screenHorizontal,
                16,
              ),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.shipments),
                    child: const Text('View requests & bids'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.postLoad),
                    child: const Text('Post another load'),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
