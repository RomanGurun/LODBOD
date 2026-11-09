import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/date_ext.dart';
import '../../../core/extensions/num_ext.dart';
import '../../../domain/entities/shipment.dart';
import '../../../domain/enums/cargo_category.dart';
import '../../../domain/enums/shipment_status.dart';
import '../../../domain/enums/vehicle_type.dart';
import '../../../shared/widgets/skeletons.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../bids/widgets/bid_card.dart';
import '../providers/shipment_notifier.dart';
import '../providers/shipment_providers.dart';

class ShipmentDetailScreen extends ConsumerWidget {
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentAsync = ref.watch(shipmentByIdProvider(shipmentId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shipmentDetails)),
      body: shipmentAsync.when(
        loading: () => const ShipmentDetailSkeleton(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(shipmentNotifierProvider.notifier).refresh(),
        ),
        data: (shipment) {
          if (shipment == null) {
            return const EmptyState(
              title: 'Shipment not found',
              subtitle: 'It may have been removed.',
              icon: Icons.search_off,
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(shipmentNotifierProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.screenHorizontal),
              children: [
                _HeaderCard(shipment: shipment),
                const SizedBox(height: AppSizes.md),
                _CargoCard(shipment: shipment),
                const SizedBox(height: AppSizes.md),
                _ScheduleCard(shipment: shipment),
                if (shipment.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  _NotesCard(notes: shipment.notes),
                ],
                const SizedBox(height: AppSizes.md),
                _TimelineCard(shipment: shipment),
                const SizedBox(height: AppSizes.md),
                _BidsSection(shipment: shipment),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shipment.reference,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              StatusBadge(status: shipment.status),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            shipment.routeLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.md),
          _LocationRow(
            icon: Icons.trip_origin,
            color: AppColors.statusOpen,
            city: shipment.pickupCity,
            address: shipment.pickupAddress,
          ),
          const SizedBox(height: AppSizes.sm),
          _LocationRow(
            icon: Icons.location_on_outlined,
            color: AppColors.primary,
            city: shipment.destinationCity,
            address: shipment.destinationAddress,
          ),
          if (shipment.assignedCarrier != null) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: AppSizes.iconSm,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Text(
                    'Assigned to ${shipment.assignedCarrier}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.color,
    required this.city,
    required this.address,
  });

  final IconData icon;
  final Color color;
  final String city;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: color),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                address,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CargoCard extends StatelessWidget {
  const _CargoCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.cargo,
      child: Column(
        children: [
          _InfoRow(
            label: 'Description',
            value: shipment.cargoDescription,
          ),
          _InfoRow(
            label: 'Category',
            value: CargoCategory.fromWire(shipment.cargoCategory).label,
          ),
          _InfoRow(
            label: 'Weight',
            value: shipment.weight.toWeight(shipment.weightUnit),
          ),
          _InfoRow(
            label: 'Vehicle',
            value: VehicleType.fromWire(shipment.vehicleType).label,
          ),
          _InfoRow(
            label: 'Expected fare',
            value: shipment.hasExpectedFare
                ? shipment.expectedFare.toNPR()
                : 'Not set',
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.schedule,
      child: Column(
        children: [
          _InfoRow(
            label: AppStrings.pickupDate,
            value: shipment.pickupAt.formatWithTime(),
          ),
          _InfoRow(
            label: 'Posted',
            value: shipment.createdAt.formatDisplay(),
          ),
          _InfoRow(
            label: 'Last update',
            value: shipment.updatedAt.formatDisplay(),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.notes,
      child: Text(
        notes,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final steps = _stepsFor(shipment);

    return _SectionCard(
      title: AppStrings.timeline,
      child: Column(
        children: [
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                children: [
                  Icon(
                    step.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: AppSizes.iconSm,
                    color: step.$2 ? AppColors.success : AppColors.textHint,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    step.$1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: step.$2
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              step.$3 ? FontWeight.w700 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<(String, bool, bool)> _stepsFor(Shipment shipment) {
    if (shipment.status == ShipmentStatus.cancelled ||
        shipment.status == ShipmentStatus.expired) {
      return [(shipment.status.label, true, true)];
    }

    final progress = switch (shipment.status) {
      ShipmentStatus.open => 0,
      ShipmentStatus.awaitingBids => 1,
      ShipmentStatus.scheduled => 1,
      ShipmentStatus.confirmed => 2,
      ShipmentStatus.inTransit => 2,
      ShipmentStatus.delivered => 3,
      ShipmentStatus.cancelled || ShipmentStatus.expired => -1,
    };

    const labels = <String>[
      'Posted',
      'Bids received',
      'Carrier confirmed',
      'Delivered',
    ];

    return <(String, bool, bool)>[
      for (var i = 0; i < labels.length; i++)
        (labels[i], i <= progress, i == progress),
    ];
  }
}

class _BidsSection extends StatelessWidget {
  const _BidsSection({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    if (!shipment.hasBids && !shipment.isAwaitingBids) {
      return const SizedBox.shrink();
    }

    final bids = [...shipment.bids]..sort((a, b) => a.fare.compareTo(b.fare));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.bids,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSizes.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusChip),
              ),
              child: Text(
                '${bids.length}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        if (bids.isEmpty)
          const EmptyState(
            title: AppStrings.noBids,
            subtitle: AppStrings.noBidsSubtitle,
            icon: Icons.gavel_outlined,
          )
        else
          for (final bid in bids) BidCard(shipment: shipment, bid: bid),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
