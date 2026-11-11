import 'package:flutter/material.dart';

import 'package:lodbod/core/theme/tokens.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = AppSizes.loginLogo});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.local_shipping_rounded,
        color: AppColors.textOnPrimary,
        size: size * 0.54,
      ),
    );
  }
}
