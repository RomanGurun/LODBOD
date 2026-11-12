import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/domain/entities/phone_verification.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/core/di/repository_providers.dart';

/// Transient state for one phone-verification attempt.
///
/// The verification ID is held in memory only for the current app process. It
/// is never written to MockAPI, disk or the user profile.
class PhoneAuthState {
  const PhoneAuthState({
    this.phoneNumber = '',
    this.verificationId,
    this.resendToken,
    this.isSending = false,
    this.isVerifying = false,
    this.error,
    this.autoVerified = false,
  });

  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final bool isSending;
  final bool isVerifying;
  final String? error;
  final bool autoVerified;

  bool get hasVerification => (verificationId ?? '').isNotEmpty;

  PhoneAuthState copyWith({
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    bool? isSending,
    bool? isVerifying,
    String? error,
    bool? autoVerified,
    bool clearError = false,
  }) {
    return PhoneAuthState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      isSending: isSending ?? this.isSending,
      isVerifying: isVerifying ?? this.isVerifying,
      error: clearError ? null : (error ?? this.error),
      autoVerified: autoVerified ?? this.autoVerified,
    );
  }
}

class PhoneAuthController extends Notifier<PhoneAuthState> {
  /// Credentials held in memory only for the current OTP attempt, then
  /// cleared. The password is never put in [PhoneAuthState], logged, or
  /// persisted.
  String? _pendingPassword;
  String? _pendingEmail;

  /// Every email account whose profile shares the typed phone number.
  ///
  /// The app used to allow the same number to be registered with several
  /// emails, so one lookup can legitimately return multiple profiles. The
  /// typed password is checked against each of them in turn.
  List<String> _pendingEmails = const <String>[];

  /// True when the phone belongs to an existing email account and must be
  /// linked to it instead of creating a second phone-only user.
  bool _linkingExistingAccount = false;

  @override
  PhoneAuthState build() => const PhoneAuthState();

  /// Checks the password for [phoneNumber], then sends a Firebase OTP.
  ///
  /// Registration creates the email/password account first, so the phone is
  /// recovered from the saved profile and the verified phone is linked to that
  /// same UID. Returns null when any check fails; the readable error is on
  /// [state] and no SMS is sent.
  Future<PhoneVerification?> request({
    required String phoneNumber,
    String? password,
    bool resend = false,
  }) async {
    final token = resend ? state.resendToken : null;

    if (!resend) {
      final candidate = password?.trim() ?? '';
      if (candidate.isEmpty) {
        state = state.copyWith(
          phoneNumber: phoneNumber,
          error: 'Enter your password to continue.',
        );
        return null;
      }

      state = state.copyWith(
        phoneNumber: phoneNumber,
        isSending: true,
        clearError: true,
      );

      List<UserProfile> profiles;
      try {
        profiles = await ref
            .read(userProfileRepositoryProvider)
            .findAllByPhone(phoneNumber);
      } on AppException catch (error) {
        state = state.copyWith(isSending: false, error: error.message);
        return null;
      } catch (_) {
        state = state.copyWith(
          isSending: false,
          error: 'Could not load your account. Check your connection and try '
              'again.',
        );
        return null;
      }

      // Newest profile first, so the account the user most likely created is
      // tried before older duplicates.
      final emails = profiles
          .map((profile) => profile.email.trim().toLowerCase())
          .where((email) => email.isNotEmpty)
          .toSet()
          .toList();

      if (emails.isEmpty) {
        state = state.copyWith(
          phoneNumber: phoneNumber,
          isSending: false,
          error: 'No account found for this number. Create an account first.',
        );
        return null;
      }

      _pendingPassword = candidate;
      _pendingEmails = emails;
      _linkingExistingAccount = true;
    }

    if (resend) {
      state = state.copyWith(
        phoneNumber: phoneNumber,
        isSending: true,
        clearError: true,
      );
    }

    try {
      final repository = ref.read(authRepositoryProvider);
      final PhoneVerification result;
      if (_linkingExistingAccount) {
        result = await _requestLink(repository, phoneNumber, token);
      } else {
        result = await repository.requestPhoneVerification(
          phoneNumber: phoneNumber,
          resendToken: token,
        );
      }

      if (result.autoVerifiedUser != null) {
        ref
            .read(authNotifierProvider.notifier)
            .adoptUser(result.autoVerifiedUser!);
        _clearPending();
        state = state.copyWith(
          isSending: false,
          autoVerified: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          verificationId: result.verificationId,
          resendToken: result.resendToken ?? token,
          isSending: false,
          clearError: true,
        );
      }
      return result;
    } on AppException catch (error) {
      _cancelLink();
      _clearPending();
      state = state.copyWith(isSending: false, error: error.message);
      return null;
    } catch (_) {
      _cancelLink();
      _clearPending();
      state = state.copyWith(
        isSending: false,
        error: AppStrings.genericError,
      );
      return null;
    }
  }

  /// Asks Firebase for the OTP, proving the typed password first.
  ///
  /// Older records may share a phone number across several email accounts. The
  /// password is tried against every candidate; the SMS is only sent after one
  /// succeeds, and that email is remembered for [verify].
  Future<PhoneVerification> _requestLink(
    IAuthRepository repository,
    String phoneNumber,
    int? token,
  ) async {
    Object? lastError;
    for (final email in _pendingEmails) {
      try {
        final result = await repository.requestPhoneLink(
          phoneNumber: phoneNumber,
          email: email,
          password: _pendingPassword!,
          resendToken: token,
        );
        _pendingEmail = email;
        return result;
      } on AppException catch (error) {
        lastError = error;
        // A credential mismatch is worth retrying against the next account.
        // Network and rate-limit failures are not.
        if (error.message != AppStrings.invalidCredentials) rethrow;
      }
    }

    if (_pendingEmails.length > 1) {
      throw const AuthException(
        'That password did not match the account linked to this number. '
        'Sign in with your email address instead.',
      );
    }
    throw lastError is AppException
        ? lastError
        : const AuthException(AppStrings.invalidCredentials);
  }

  /// Verifies the code with Firebase. Returns true when the session was
  /// created; the auth state then drives navigation.
  Future<bool> verify(String code) async {
    final verificationId = state.verificationId;
    if ((verificationId ?? '').isEmpty) {
      state = state.copyWith(
        error: 'Request a new code to continue.',
      );
      return false;
    }

    final trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      state = state.copyWith(error: 'Enter the 6-digit code from the SMS.');
      return false;
    }

    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = _linkingExistingAccount
          ? await repository.verifyPhoneLink(
              phoneNumber: state.phoneNumber,
              verificationId: verificationId!,
              smsCode: trimmed,
              email: _pendingEmail!,
              password: _pendingPassword!,
            )
          : await repository.verifyPhoneOtp(
              verificationId: verificationId!,
              smsCode: trimmed,
            );
      _clearPending();
      ref.read(authNotifierProvider.notifier).adoptUser(user);
      state = state.copyWith(
        isVerifying: false,
        autoVerified: true,
        clearError: true,
      );
      return true;
    } on AppException catch (error) {
      state = state.copyWith(isVerifying: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isVerifying: false,
        error: AppStrings.genericError,
      );
      return false;
    }
  }

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  void _cancelLink() {
    if (!_linkingExistingAccount) return;
    unawaited(
      ref.read(authRepositoryProvider).cancelPhoneLink().catchError((_) {}),
    );
  }

  void _clearPending() {
    _pendingPassword = null;
    _pendingEmail = null;
    _pendingEmails = const <String>[];
    _linkingExistingAccount = false;
  }

  void clear() {
    _cancelLink();
    _clearPending();
    state = const PhoneAuthState();
  }
}

final phoneAuthControllerProvider =
    NotifierProvider<PhoneAuthController, PhoneAuthState>(
  PhoneAuthController.new,
);
