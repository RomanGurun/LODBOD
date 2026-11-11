import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/core/utils/validators.dart';
import 'package:lodbod/shared/widgets/app_text_field.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';

/// Registration screen — creates the email/password account first and saves the
/// phone number to the profile.
///
/// The phone is verified the first time the user signs in with it. Phone login
/// checks the account password and links the verified number to the same UID,
/// so both tabs open one account.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          phone: PhoneNumber.toE164(_phoneController.text),
        );
    // The router moves on as soon as auth and the profile are ready.
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError ? authState.error.toString() : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToLogin,
        ),
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenHorizontal,
            8,
            AppSizes.screenHorizontal,
            AppSizes.md,
          ),
          child: Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Form fields — matching spec measurements h=45/46 each
                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'John Doe',
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      hint: '98XXXXXXXX',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      prefixText: '${PhoneNumber.nepalDialCode} ',
                      prefixStyle: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppTypography.body,
                        color: AppColors.textSecondary,
                      ),
                      validator: Validators.nepalMobile,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email address',
                      hint: 'you@company.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Min 6 characters',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: AppSizes.iconMd,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hint: 'Re-enter your password',
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!isLoading) _submit();
                      },
                      validator: (v) => Validators.confirmPassword(
                        v,
                        _passwordController.text,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        icon: Icon(
                          _obscureConfirmPassword
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
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 40),

                    // Create account button
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
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
