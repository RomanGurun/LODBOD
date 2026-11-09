import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFDF3A0C);
  static const Color primaryLight = Color(0xFFFF6B3D);
  static const Color primaryDark = Color(0xFFB02D09);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFEEEEEE);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color statusOpen = Color(0xFF1565C0);
  static const Color statusOpenBg = Color(0xFFE3F2FD);

  static const Color statusAwaitingBids = Color(0xFFE65100);
  static const Color statusAwaitingBidsBg = Color(0xFFFFF3E0);

  static const Color statusScheduled = Color(0xFF6A1B9A);
  static const Color statusScheduledBg = Color(0xFFF3E5F5);

  static const Color statusConfirmed = Color(0xFF1B5E20);
  static const Color statusConfirmedBg = Color(0xFFE8F5E9);

  static const Color statusInTransit = Color(0xFFDF3A0C);
  static const Color statusInTransitBg = Color(0xFFFFEBE5);

  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusDeliveredBg = Color(0xFFC8E6C9);

  static const Color statusCancelled = Color(0xFFB71C1C);
  static const Color statusCancelledBg = Color(0xFFFFCDD2);

  // Utility
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
