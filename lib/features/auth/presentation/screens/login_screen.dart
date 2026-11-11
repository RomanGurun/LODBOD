import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/core/utils/validators.dart';
import 'package:lodbod/shared/widgets/app_text_field.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/providers/phone_auth_controller.dart';
import 'package:lodbod/features/auth/presentation/widgets/auth_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthMode { phone, email }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phonePasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.phone;
  bool _obscurePhonePassword = true;
  bool _obscureEmailPassword = true;
  bool _keepSignedIn = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _phonePasswordController.dispose();
    _emailController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    FocusScope.of(context).unfocus();
    // Abandon any pending OTP/link attempt, including the secondary Firebase
    // session the phone-link flow keeps open while the code is entered.
    ref.read(phoneAuthControllerProvider.notifier).clear();
    _phonePasswordController.clear();
    _emailPasswordController.clear();
    setState(() => _mode = mode);
  }

  Future<void> _sendOtp() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final result = await ref.read(phoneAuthControllerProvider.notifier).request(
          phoneNumber: PhoneNumber.toE164(_phoneController.text),
          password: _phonePasswordController.text,
        );
    if (!mounted || result == null) return;

    // Android can verify the number without any code entry. The auth state is
    // already updated, so the router takes over.
    if (result.autoVerifiedUser != null) return;

    context.push(AppRoutes.otp);
  }

  Future<void> _submitEmail() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _emailPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phoneState = ref.watch(phoneAuthControllerProvider);

    final busy =
        _mode == _AuthMode.phone ? phoneState.isSending : authState.isLoading;
    final error = _mode == _AuthMode.phone
        ? phoneState.error
        : authState.hasError
            ? authState.error.toString()
            : null;

    return AuthPage(
      title: AppStrings.authTitle,
      subtitle: AppStrings.authSubtitle,
      children: [
        _AuthTabs(
          mode: _mode,
          onChanged: (mode) => _switchMode(mode),
        ),
        const SizedBox(height: 26),
        if (_mode == _AuthMode.phone) _buildPhoneForm() else _buildEmailForm(),
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
        const SizedBox(height: AppSizes.md),
        FilledButton(
          onPressed: busy
              ? null
              : _mode == _AuthMode.phone
                  ? _sendOtp
                  : _submitEmail,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Text(
                  _mode == _AuthMode.phone
                      ? AppStrings.signInSendOtp
                      : AppStrings.login,
                ),
        ),
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
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _phoneController,
            label: AppStrings.phoneNumber,
            hint: AppStrings.phoneHint,
            prefixText: '${PhoneNumber.nepalDialCode} ',
            prefixStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.body,
              color: AppColors.textSecondary,
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: Validators.nepalMobile,
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: _phonePasswordController,
            label: AppStrings.password,
            hint: 'Enter your account password',
            obscureText: _obscurePhonePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: Validators.password,
            onSubmitted: (_) {
              if (!ref.read(phoneAuthControllerProvider).isSending) {
                _sendOtp();
              }
            },
            suffixIcon: IconButton(
              tooltip:
                  _obscurePhonePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() => _obscurePhonePassword = !_obscurePhonePassword);
              },
              icon: Icon(
                _obscurePhonePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppSizes.iconMd,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            "We'll check your password, then text a 6-digit code to this "
            'number. The code must be verified by Firebase.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.register),
            child: const Text('Create a shipper account'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailController,
            label: 'Email address',
            hint: 'you@company.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: _emailPasswordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscureEmailPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) {
              if (!ref.read(authNotifierProvider).isLoading) {
                _submitEmail();
              }
            },
            validator: Validators.password,
            suffixIcon: IconButton(
              tooltip:
                  _obscureEmailPassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(
                  () => _obscureEmailPassword = !_obscureEmailPassword,
                );
              },
              icon: Icon(
                _obscureEmailPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppSizes.iconMd,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: _keepSignedIn,
                  onChanged: (value) {
                    setState(() => _keepSignedIn = value ?? false);
                  },
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  'Keep me signed in',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
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
          const SizedBox(height: AppSizes.sm),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.register),
            child: const Text('Create a shipper account'),
          ),
        ],
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

/// Two-segment Phone / Email switch.
class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

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
      child: Row(
        children: [
          _segment(
            label: AppStrings.phoneTab,
            value: _AuthMode.phone,
            icon: Icons.phone_iphone,
          ),
          _segment(
            label: AppStrings.emailTab,
            value: _AuthMode.email,
            icon: Icons.mail_outline,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required _AuthMode value,
    required IconData icon,
  }) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        key: ValueKey<String>('auth-tab-${label.toLowerCase()}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
