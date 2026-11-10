import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Hero card greeting the shipper with the mobile request budget:
/// title, caption, a usage bar and the "+ Post Load" call to action.
class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.used,
    required this.limit,
    required this.onPostLoad,
  });

  final int used;
  final int limit;
  final VoidCallback onPostLoad;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 95,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: ColoredBox(color: AppColors.surface)),
            const Positioned.fill(child: _HeroBands()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 0, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppStrings.shipSomethingNew,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '${AppStrings.mobileRequestsUsed} '
                              '$used ${AppStrings.of} $limit',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 13),
                        child: _PostLoadButton(onPostLoad: onPostLoad),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _RequestBar(fraction: fraction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostLoadButton extends StatelessWidget {
  const _PostLoadButton({required this.onPostLoad});

  final VoidCallback onPostLoad;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPostLoad,
        child: SizedBox(
          width: 117,
          height: 41,
          child: Center(
            child: Text(
              AppStrings.postLoadCta,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontSize: 13, color: AppColors.textOnPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestBar extends StatelessWidget {
  const _RequestBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: ColoredBox(color: AppColors.border)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: const ColoredBox(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The decorative diagonal ribbons behind the hero content, clipped to
/// the card. Approximated from the reference illustration.
class _HeroBands extends StatelessWidget {
  const _HeroBands();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _HeroBandsPainter());
  }
}

class _HeroBandsPainter extends CustomPainter {
  const _HeroBandsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    const angle = -math.pi / 6;

    void ribbon(
      Color color,
      Offset center,
      double ribbonWidth,
      double ribbonHeight,
      double radius,
    ) {
      final paint = Paint()..color = color;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: ribbonWidth,
            height: ribbonHeight,
          ),
          Radius.circular(radius),
        ),
        paint,
      );
      canvas.restore();
    }

    // Grey ribbon sweeping behind the request bar.
    ribbon(
      AppColors.surfaceVariant,
      Offset(width * 0.55, height * 0.72),
      width * 1.35,
      36,
      18,
    );
    // Soft orange ribbon sweeping behind the post button.
    ribbon(
      AppColors.primarySoft,
      Offset(width * 0.82, height * 0.40),
      width * 1.15,
      26,
      13,
    );
    // Soft accents peeking over the bottom corners.
    ribbon(
      AppColors.primarySoft,
      Offset(width * 0.04, height * 1.02),
      90,
      26,
      13,
    );
    ribbon(
      AppColors.primarySoft,
      Offset(width * 0.97, height * 1.04),
      80,
      26,
      13,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroBandsPainter oldDelegate) => false;
}
