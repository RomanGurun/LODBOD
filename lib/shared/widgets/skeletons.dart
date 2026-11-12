import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:lodbod/core/theme/tokens.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppSizes.radiusSm,
    this.border = false,
    this.child,
  });

  final double? width;
  final double height;
  final double radius;
  final bool border;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Intentionally a plain box: the animated [Shimmer] lives once at the
    // skeleton root so a screen with 16 placeholders runs one animation
    // instead of sixteen independent controllers and shader masks.
    return Container(
      width: width,
      height: height,
      clipBehavior: child == null ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
    );
  }
}

/// Single shimmer + repaint boundary shared by every placeholder on screen.
class _SkeletonShimmer extends StatelessWidget {
  const _SkeletonShimmer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: child,
      ),
    );
  }
}

class ShipmentListSkeleton extends StatelessWidget {
  const ShipmentListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return _SkeletonShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.screenHorizontal),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.sm),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 96, height: 14),
                    Spacer(),
                    ShimmerBox(
                      width: 72,
                      height: 22,
                      radius: AppSizes.radiusChip,
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.sm),
                ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: AppSizes.xs),
                ShimmerBox(width: 180, height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ShipmentDetailSkeleton extends StatelessWidget {
  const ShipmentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonShimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.screenHorizontal),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _SkeletonSection(height: 120),
          SizedBox(height: AppSizes.md),
          _SkeletonSection(height: 150),
          SizedBox(height: AppSizes.md),
          _SkeletonSection(height: 110),
        ],
      ),
    );
  }
}

class _SkeletonSection extends StatelessWidget {
  const _SkeletonSection({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 120, height: 14),
          SizedBox(height: AppSizes.sm),
          ShimmerBox(width: double.infinity, height: 10),
          SizedBox(height: AppSizes.xs),
          ShimmerBox(width: 200, height: 10),
        ],
      ),
    );
  }
}
