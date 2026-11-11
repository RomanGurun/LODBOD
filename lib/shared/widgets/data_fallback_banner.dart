import 'package:flutter/material.dart';

import 'package:lodbod/core/constants/app_colors.dart';
import 'package:lodbod/core/constants/app_sizes.dart';

class DataFallbackBanner extends StatelessWidget {
  const DataFallbackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.statusAwaitingBidsBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHorizontal,
          vertical: AppSizes.sm,
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              size: AppSizes.iconSm,
              color: AppColors.statusAwaitingBids,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                'Live API unavailable — showing local demo data',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.statusAwaitingBids,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
