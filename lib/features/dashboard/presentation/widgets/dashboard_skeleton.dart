import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/theme/tokens.dart';

/// Loading state mirroring the reference skeleton: greeting, hero, stats,
/// action, and recent blocks shimmering above a centered hint.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenHorizontal,
        8,
        AppSizes.screenHorizontal,
        24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _GreetingBones(),
              SizedBox(height: 16),
              _HeroBone(),
              SizedBox(height: 12),
              _StatsBones(),
              SizedBox(height: 16),
              _Bar(width: 150, height: 12, radius: 6),
              SizedBox(height: 12),
              _ActionBone(),
              SizedBox(height: 16),
              _RecentHeaderBones(),
              SizedBox(height: 16),
              _RecentBone(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            AppStrings.loadingShipments,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

/// A bone swept by the shared shimmer ancestor.
class _Bone extends StatelessWidget {
  const _Bone({
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

/// A lighter detail bar inside a bone.
class _Bar extends StatelessWidget {
  const _Bar({
    this.width,
    required this.height,
    this.radius = AppSizes.radiusSm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerHighlight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _GreetingBones extends StatelessWidget {
  const _GreetingBones();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _Bone(width: 40, height: 40, radius: 20, border: true),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Bar(width: 134, height: 12, radius: 6),
            SizedBox(height: 8),
            _Bar(width: 165, height: 12, radius: 6),
          ],
        ),
        Spacer(),
        _Bone(width: 38, height: 38, radius: 19, border: true),
      ],
    );
  }
}

class _HeroBone extends StatelessWidget {
  const _HeroBone();

  @override
  Widget build(BuildContext context) {
    return _Bone(
      height: 107,
      radius: AppSizes.radiusLg,
      border: true,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Bar(width: 170, height: 16, radius: 4),
                Spacer(),
                _Bar(width: 117, height: 41, radius: AppSizes.radiusMd),
              ],
            ),
            SizedBox(height: 8),
            _Bar(width: 174, height: 12, radius: 4),
            Spacer(),
            _Bar(height: 6, radius: 3),
            SizedBox(height: 19),
          ],
        ),
      ),
    );
  }
}

class _StatsBones extends StatelessWidget {
  const _StatsBones();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(child: _StatBone()),
        SizedBox(width: 12),
        Expanded(child: _StatBone()),
        SizedBox(width: 12),
        Expanded(child: _StatBone()),
      ],
    );
  }
}

class _StatBone extends StatelessWidget {
  const _StatBone();

  @override
  Widget build(BuildContext context) {
    return _Bone(
      height: 106,
      radius: AppSizes.radiusLg,
      border: true,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Bar(width: 28, height: 28, radius: 14),
            SizedBox(height: 6),
            _Bar(width: 32, height: 22, radius: 4),
            SizedBox(height: 2),
            _Bar(width: 48, height: 10, radius: 4),
          ],
        ),
      ),
    );
  }
}

class _ActionBone extends StatelessWidget {
  const _ActionBone();

  @override
  Widget build(BuildContext context) {
    return _Bone(
      height: 60,
      radius: AppSizes.radiusLg,
      border: true,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            _Bar(width: 36, height: 36, radius: 18),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Bar(width: 180, height: 13, radius: 4),
                SizedBox(height: 4),
                _Bar(width: 150, height: 10, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentHeaderBones extends StatelessWidget {
  const _RecentHeaderBones();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _Bar(width: 110, height: 12, radius: 6),
        Spacer(),
        _Bar(width: 44, height: 12, radius: 6),
      ],
    );
  }
}

class _RecentBone extends StatelessWidget {
  const _RecentBone();

  @override
  Widget build(BuildContext context) {
    return _Bone(
      height: 139,
      radius: AppSizes.radiusLg,
      border: true,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Bar(width: 70, height: 14, radius: 4),
                Spacer(),
                _Bar(width: 64, height: 22, radius: 11),
              ],
            ),
            SizedBox(height: 10),
            _Bar(width: 126, height: 13, radius: 4),
            SizedBox(height: 8),
            Row(
              children: <Widget>[
                _Bar(width: 11, height: 11, radius: 2),
                SizedBox(width: 5),
                _Bar(width: 150, height: 11, radius: 4),
              ],
            ),
            SizedBox(height: 12),
            _Bar(height: 2, radius: 1),
            SizedBox(height: 12),
            Row(
              children: <Widget>[
                _Bar(width: 13, height: 13, radius: 2),
                SizedBox(width: 5),
                Expanded(child: _Bar(height: 11, radius: 4)),
                SizedBox(width: 8),
                _Bar(width: 70, height: 16, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
