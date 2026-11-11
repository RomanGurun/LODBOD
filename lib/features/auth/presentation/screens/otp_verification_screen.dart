import 'dart:async';

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
import 'package:lodbod/features/auth/presentation/providers/phone_auth_controller.dart';
import 'package:lodbod/features/auth/presentation/widgets/auth_page.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int _cooldownSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = _cooldownSeconds;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(phoneAuthControllerProvider.notifier).verify(
          _codeController.text,
        );
    // Navigation on success is handled by the router once auth becomes ready.
  }

  Future<void> _resend() async {
    final notifier = ref.read(phoneAuthControllerProvider.notifier);
    final phone = ref.read(phoneAuthControllerProvider).phoneNumber;
    final result = await notifier.request(phoneNumber: phone, resend: true);
    if (!mounted || result == null) return;
    _codeController.clear();
    _startCooldown();
  }

  void _changeNumber() {
    ref.read(phoneAuthControllerProvider.notifier).clear();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneAuthControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    if (state.phoneNumber.isEmpty) {
      return AuthPage(
        title: AppStrings.otpTitle,
        subtitle: AppStrings.codeExpired,
        showLogo: false,
        showBack: true,
        onBack: _changeNumber,
        children: [
          FilledButton(
            onPressed: _changeNumber,
            child: const Text(AppStrings.changePhoneNumber),
          ),
        ],
      );
    }

    return AuthPage(
      title: AppStrings.otpTitle,
      subtitle:
          '${AppStrings.otpSubtitle} ${PhoneNumber.mask(state.phoneNumber)}',
      showLogo: false,
      showBack: true,
      onBack: _changeNumber,
      children: [
        Form(
          key: _formKey,
          child: AppTextField(
            controller: _codeController,
            label: AppStrings.otpCodeLabel,
            hint: '123456',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            autofocus: true,
            textAlign: TextAlign.center,
            letterSpacing: 8,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: Validators.otpCode,
            onSubmitted: (_) {
              if (!state.isVerifying) _verify();
            },
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppSizes.sm),
          Text(
            state.error!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSizes.lg),
        FilledButton(
          onPressed: state.isVerifying ? null : _verify,
          child: state.isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : const Text(AppStrings.verifyOtp),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _secondsRemaining == 0 && !state.isSending
                      ? _resend
                      : null,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    state.isSending
                        ? 'Sending…'
                        : _secondsRemaining > 0
                            ? AppStrings.resendIn.replaceFirst(
                                '{seconds}',
                                '$_secondsRemaining',
                              )
                            : AppStrings.resendOtp,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _changeNumber,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    AppStrings.changePhoneNumber,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
