import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/utils/phone_number.dart';
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
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(
      onKeyEvent: (node, event) => _handleKeyEvent(index, event),
    ),
  );

  String? _validationError;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _focusNodes[i].addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        setState(() {});
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.removeListener(_onFocusChanged);
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
    if (ref.read(phoneAuthControllerProvider).error != null) {
      ref.read(phoneAuthControllerProvider.notifier).clearError();
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      // User pasted or autofilled a multi-digit code
      for (var i = 0; i < 6 && (index + i) < 6; i++) {
        if (i < digits.length) {
          _controllers[index + i].text = digits[i];
        }
      }
      final nextIndex = (index + digits.length).clamp(0, 5);
      _focusNodes[nextIndex].requestFocus();
      setState(() {});
      return;
    }

    if (digits.isNotEmpty) {
      _controllers[index].text = digits;
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }
    setState(() {});
  }

  Future<void> _verify() async {
    final code = _code.trim();
    if (code.length < 6) {
      setState(() => _validationError = 'Enter the 6-digit code');
      return;
    }

    setState(() => _validationError = null);
    FocusScope.of(context).unfocus();

    final success =
        await ref.read(phoneAuthControllerProvider.notifier).verify(code);
    if (!mounted) return;
    if (!success) {
      // Delete all entered OTP digits on wrong/failed code
      for (final controller in _controllers) {
        controller.clear();
      }
      // Return focus to first box for immediate re-entry
      _focusNodes[0].requestFocus();
      setState(() {});
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
        showBack: false,
        children: [
          FilledButton(
            onPressed: () {
              ref.read(phoneAuthControllerProvider.notifier).clear();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      );
    }

    final hasError = state.error != null || _validationError != null;

    return AuthPage(
      title: AppStrings.otpTitle,
      subtitle:
          '${AppStrings.otpSubtitle} ${PhoneNumber.mask(state.phoneNumber)}',
      showLogo: false,
      showBack: false,
      children: [
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final gap = availableWidth < 340
                  ? 6.0
                  : (availableWidth < 380 ? 8.0 : 10.0);
              final boxWidth =
                  ((availableWidth - (5 * gap)) / 6).clamp(38.0, 52.0);
              final boxHeight = (boxWidth * 1.18).clamp(48.0, 58.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row of 6 individual, responsive OTP input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final isFocused = _focusNodes[index].hasFocus;
                      final isFilled = _controllers[index].text.isNotEmpty;

                      final borderColor = hasError
                          ? AppColors.error
                          : isFocused
                              ? AppColors.primary
                              : isFilled
                                  ? AppColors.textPrimary
                                  : AppColors.border;

                      return SizedBox(
                        width: boxWidth,
                        height: boxHeight,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofocus: index == 0,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasError
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: hasError
                                ? AppColors.error.withValues(alpha: 0.04)
                                : isFocused
                                    ? AppColors.primarySoft
                                        .withValues(alpha: 0.25)
                                    : AppColors.surface,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              borderSide: BorderSide(
                                color: borderColor,
                                width: isFilled ? 1.5 : 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              borderSide: BorderSide(
                                color: borderColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
                        ),
                      );
                    }),
                  ),
                  if (_validationError != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      _validationError!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeight,
          child: FilledButton(
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
        ),
      ],
    );
  }
}
