import 'package:flutter/material.dart';

import 'package:lodbod/core/constants/app_colors.dart';
import 'package:lodbod/core/constants/app_sizes.dart';
import 'package:lodbod/shared/widgets/app_card.dart';

/// A single dashboard metric: tinted icon circle, big number and label.
/// Tapping it opens the shipments list filtered to this metric.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.onTap,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      borderRadius: AppSizes.radiusLg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: textTheme.displaySmall?.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
