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
          // Radial glow behind logo
          Positioned(
            top: 301 - 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primarySoft.withValues(alpha: 0.7),
                      AppColors.primarySoft.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
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
          // Bottom progress section
          Positioned(
            left: AppSizes.screenHorizontal,
            right: AppSizes.screenHorizontal,
            bottom: 49,
            child: Column(
              children: [
                // Linear progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
