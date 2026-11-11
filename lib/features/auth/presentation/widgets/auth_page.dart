import 'package:flutter/material.dart';

import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/shared/widgets/app_logo.dart';

/// Shared, scroll-safe shell for the phone/OTP/profile auth screens.
///
/// Content is capped at 420 logical pixels so it stays readable on tablets and
/// never overflows on small phones; the whole column scrolls when the keyboard
/// is open.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showLogo = true,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showLogo;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenHorizontal,
                21,
                AppSizes.screenHorizontal,
                AppSizes.md,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showLogo) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: AppLogo(),
                        ),
                        const SizedBox(height: 22),
                      ],
                      Text(
                        title,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 11),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      ...children,
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
