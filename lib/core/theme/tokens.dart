import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFDF3A0C);
  static const Color primaryAlt = Color(0xFFFF6B00);
  static const Color primaryLight = Color(0xFFFF7A52);
  static const Color primaryDark = Color(0xFFB02D09);
  static const Color primarySoft = Color(0xFFFFF0EA);

  // Backgrounds
  static const Color background = Color(0xFFF5F5F7);
  static const Color screen = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F1F4);
  static const Color surfaceMuted = Color(0xFFF8F8FA);

  // Text
  static const Color textPrimary = Color(0xFF111114);
  static const Color textTitle = Color(0xFF111114);
  static const Color textSecondary = Color(0xFF63636C);
  static const Color textHint = Color(0xFF8C8C94);
  static const Color textTertiary = Color(0xFF8C8C94);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color statusOpen = Color(0xFF1664B4);
  static const Color statusOpenBg = Color(0xFFE3EDF6);

  static const Color statusAwaitingBids = Color(0xFF1664B4);
  static const Color statusAwaitingBidsBg = Color(0xFFE3EDF6);

  static const Color statusScheduled = Color(0xFF6546C3);
  static const Color statusScheduledBg = Color(0xFFECE8F8);

  static const Color statusConfirmed = Color(0xFF1664B4);
  static const Color statusConfirmedBg = Color(0xFFE3EDF6);

  static const Color statusInTransit = Color(0xFFE03811);
  static const Color statusInTransitBg = Color(0xFFFFEADB);

  static const Color statusDelivered = Color(0xFF399777);
  static const Color statusDeliveredBg = Color(0xFFE1EFEB);

  static const Color statusCancelled = Color(0xFFB54000);
  static const Color statusCancelledBg = Color(0xFFF6ECEB);

  static const Color statusExpired = Color(0xFF63636C);
  static const Color statusExpiredBg = Color(0xFFF1F1F4);

  // Dashboard stat highlights
  static const Color statusActiveBg = Color(0xFFFBE7E1);
  static const Color infoBg = Color(0xFFE6F3FF);

  // Utility
  static const Color border = Color(0xFFE6E6EA);
  static const Color divider = Color(0xFFE6E6EA);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF399777);
  static const Color warning = Color(0xFFF0A11A);
  static const Color shimmerBase = Color(0xFFE8E7EC);
  static const Color shimmerHighlight = Color(0xFFEDEDEF);
  static const Color scrim = Color(0x66000000);

  // Shadows
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A111114),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> raisedShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1FDF3A0C),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

class AppSizes {
  AppSizes._();

  // Spacing scale
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Screen padding
  static const double screenHorizontal = 20.0;
  static const double screenVertical = 20.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusChip = 24.0;
  static const double radiusPill = 100.0;
  static const double radiusCircle = 100.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Touch targets
  static const double minTouchTarget = 48.0;
  static const double inputHeight = 46.0;
  static const double buttonHeight = 50.0;

  // Cards
  static const double cardElevation = 0.0;
  static const double borderWidth = 1.0;

  // Navigation
  static const double bottomNavHeight = 75.0;
  static const double bottomNavIcon = 22.0;
  static const double navFab = 52.0;
  static const double navFabIcon = 26.0;

  // Avatar
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;

  // Illustration / hero
  static const double splashLogo = 76.0;
  static const double loginLogo = 56.0;
  static const double successLogo = 87.0;

  // Dashboard stat cards
  static const double statHeight = 108.0;
  static const double listCardMinHeight = 134.0;
}

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';
  static const String fontFamilyFallback = 'SF Pro Text';

  static const double display = 32.0;
  static const double headline = 26.0;
  static const double title = 20.0;
  static const double section = 16.0;
  static const double body = 14.0;
  static const double caption = 12.0;
  static const double micro = 10.0;
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration page = Duration(milliseconds: 350);
  static const Duration splash = Duration(milliseconds: 900);
  static const Duration shimmer = Duration(milliseconds: 1400);
}
