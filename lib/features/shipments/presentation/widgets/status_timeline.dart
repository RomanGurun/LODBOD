import 'package:flutter/material.dart';

import 'package:lodbod/shared/extensions/date_ext.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

/// Readable shipment lifecycle timeline shared by the detail and tracking
/// screens. Steps are derived from the current status only — there is no
/// live event feed, so the timeline is indicative, not a live log.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline(
      {super.key, required this.shipment, this.compact = false});

  final Shipment shipment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final steps = _stepsFor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              children: <Widget>[
                Icon(
                  step.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: AppSizes.iconSm,
                  color: step.done ? AppColors.success : AppColors.textHint,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    step.label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: step.done
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: step.current ? FontWeight.w700 : null,
                    ),
                  ),
                ),
                if (!compact && step.detail.isNotEmpty)
                  Text(
                    step.detail,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<({String label, String detail, bool done, bool current})> _stepsFor() {
    if (shipment.status == ShipmentStatus.cancelled ||
        shipment.status == ShipmentStatus.expired) {
      return <({String label, String detail, bool done, bool current})>[
        (
          label: 'Posted',
          detail: shipment.createdAt.formatShort(),
          done: true,
          current: false,
        ),
        (
          label: shipment.status.label,
          detail: shipment.updatedAt.formatShort(),
          done: true,
          current: true,
        ),
      ];
    }

    final progress = switch (shipment.status) {
      ShipmentStatus.open => 0,
      ShipmentStatus.awaitingBids => 1,
      ShipmentStatus.scheduled => 1,
      ShipmentStatus.confirmed => 2,
      ShipmentStatus.inTransit => 3,
      ShipmentStatus.delivered => 4,
      ShipmentStatus.cancelled || ShipmentStatus.expired => -1,
    };

    final labels = <(String, String)>[
      ('Posted', shipment.createdAt.formatShort()),
      (
        'Bids received',
        shipment.bidCount == 0 ? '' : '${shipment.bidCount} bids'
      ),
      ('Carrier confirmed', shipment.updatedAt.formatShort()),
      ('In transit', ''),
      ('Delivered', ''),
    ];

    return <({String label, String detail, bool done, bool current})>[
      for (var i = 0; i < labels.length; i++)
        (
          label: labels[i].$1,
          detail: labels[i].$2,
          done: i <= progress,
          current: i == progress,
        ),
    ];
  }
}
