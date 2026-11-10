import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.md),
    this.margin,
    this.onTap,
    this.color = AppColors.surface,
    this.borderRadius = AppSizes.radiusMd,
    this.border = true,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color color;
  final double borderRadius;
  final bool border;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final decoration = BoxDecoration(
      color: color,
      borderRadius: radius,
      border: border ? Border.all(color: AppColors.border) : null,
      boxShadow: elevated ? AppColors.cardShadow : null,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return Container(margin: margin, decoration: decoration, child: content);
    }

    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
