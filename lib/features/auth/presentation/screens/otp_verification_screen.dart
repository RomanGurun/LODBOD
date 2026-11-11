import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/core/utils/validators.dart';
import 'package:lodbod/features/auth/presentation/providers/phone_auth_controller.dart';
import 'package:lodbod/features/auth/presentation/widgets/auth_page.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _focusNode.removeListener(_onFocusChanged);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(phoneAuthControllerProvider.notifier).verify(
          _codeController.text,
        );
    if (!mounted) return;
    if (!success) {
      _codeController.clear();
      _focusNode.requestFocus();
      setState(() {});
    }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final gap = availableWidth < 340
                  ? 6.0
                  : (availableWidth < 380 ? 8.0 : 10.0);
              final boxWidth =
                  ((availableWidth - (5 * gap)) / 6).clamp(36.0, 52.0);
              final boxHeight = (boxWidth * 1.22).clamp(46.0, 58.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _focusNode.requestFocus(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Responsive 6 visual boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            final text = _codeController.text;
                            final isFilled = index < text.length;
                            final char = isFilled ? text[index] : '';
                            final isFocused = _focusNode.hasFocus &&
                                (index == text.length ||
                                    (index == 5 && text.length == 6));
                            final hasError = state.error != null;

                            final borderColor = hasError
                                ? AppColors.error
                                : isFocused
                                    ? AppColors.primary
                                    : isFilled
                                        ? AppColors.textPrimary
                                        : AppColors.border;

                            final borderWidth =
                                (isFocused || hasError) ? 2.0 : 1.0;

                            return Container(
                              width: boxWidth,
                              height: boxHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: hasError
                                    ? AppColors.error.withValues(alpha: 0.04)
                                    : isFocused
                                        ? AppColors.primarySoft
                                            .withValues(alpha: 0.2)
                                        : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                                border: Border.all(
                                  color: borderColor,
                                  width: borderWidth,
                                ),
                                boxShadow: isFocused
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                char,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: hasError
                                      ? AppColors.error
                                      : AppColors.textPrimary,
                                ),
                              ),
                            );
                          }),
                        ),

                        // Transparent TextFormField overlaid for keyboard capture, SMS autofill, and validation
                        TextFormField(
                          controller: _codeController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.transparent,
                            fontSize: 1,
                            height: 1,
                          ),
                          cursorColor: Colors.transparent,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: (boxHeight - 1) / 2,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            errorStyle: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: Validators.otpCode,
                          onChanged: (value) {
                            if (state.error != null) {
                              ref
                                  .read(phoneAuthControllerProvider.notifier)
                                  .clearError();
                            }
                          },
                          onFieldSubmitted: (_) {
                            if (!state.isVerifying) _verify();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppSizes.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    state.error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
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
        Center(
          child: TextButton(
            onPressed: _changeNumber,
            child: const Text(AppStrings.changePhoneNumber),
          ),
        ),
      ],
    );
  }
}
