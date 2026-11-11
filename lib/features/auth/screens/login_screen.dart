import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/router/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/utils/validators.dart';
import 'package:lodbod/shared/widgets/app_logo.dart';
import 'package:lodbod/shared/widgets/app_text_field.dart';
import 'package:lodbod/features/auth/providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _keepSignedIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error.toString() : null;

    return Scaffold(
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 25,
                  maxWidth: 420,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: AppLogo(),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          AppStrings.loginTitle,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 11),
                        Text(
                          AppStrings.loginSubtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        const _EmailSegment(),
                        const SizedBox(height: 34),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email address',
                          hint: 'you@company.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 33),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) {
                            if (!isLoading) _submit();
                          },
                          validator: Validators.password,
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: AppSizes.iconMd,
                            ),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            error,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Checkbox(
                                value: _keepSignedIn,
                                onChanged: (value) {
                                  setState(
                                    () => _keepSignedIn = value ?? false,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              'Keep me signed in',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _showResetPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnPrimary,
                                  ),
                                )
                              : const Text('Log in'),
                        ),
                        const SizedBox(height: AppSizes.md),
                        const _OrDivider(),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text('Create a shipper account'),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSizes.lg),
                        const Text(
                          'By continuing you agree to the Terms and Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppTypography.caption,
                            color: AppColors.textTertiary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showResetPassword() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: Text(
          'Password reset is not available in this demo.\n\n'
          'Use ${AppStrings.demoEmail} with password '
          '${AppStrings.demoPassword}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.gotIt),
          ),
        ],
      ),
    );
  }
}

class _EmailSegment extends StatelessWidget {
  const _EmailSegment();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.inputHeight,
      padding: const EdgeInsets.all(AppSizes.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Email',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
