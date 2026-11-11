import 'package:flutter/material.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/shared/widgets/app_logo.dart';

/// Branded cold-start screen shown while the session is restored.
///
/// The logo block is centred in the full safe area and the progress section is
/// pinned to the bottom with token spacing — no absolute offsets — so the
/// layout stays balanced on small phones, tablets and in landscape.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the splash content readable on tablets/desktop while
            // filling the width on phones.
            final contentWidth =
                constraints.maxWidth > 480 ? 480.0 : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHorizontal,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      FadeTransition(
                        opacity: _fade,
                        child: ScaleTransition(
                          scale: _scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _SplashLogo(),
                              const SizedBox(height: 24),
                              Text(
                                AppStrings.appName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: AppColors.textTitle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'SHIPPER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: _SplashFooter(fade: _fade),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The app mark with the soft radial brand glow behind it. The glow is laid
/// out around the logo instead of at a fixed screen offset, so it stays
/// perfectly centred at any size.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.splashLogo,
      height: AppSizes.splashLogo,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -72,
            top: -72,
            right: -72,
            bottom: -72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primarySoft.withValues(alpha: 0.9),
                    AppColors.primarySoft.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          const AppLogo(size: AppSizes.splashLogo),
        ],
      ),
    );
  }
}

class _SplashFooter extends StatelessWidget {
  const _SplashFooter({required this.fade});

  final Animation<double> fade;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  style: textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text('v1.0.0', style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
