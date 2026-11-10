import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 301),
              const AppLogo(size: AppSizes.splashLogo),
              const SizedBox(height: 29),
              Text(
                AppStrings.appName,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textTitle,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SHIPPER',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Positioned(
            left: AppSizes.screenHorizontal,
            right: AppSizes.screenHorizontal,
            bottom: 49,
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'Checking your session...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
