import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart' as core;

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/phone_verification.dart';

/// Thin, mockable boundary around `firebase_auth`.
///
/// Widget/unit tests can provide a fake implementation so no real SMS is sent
/// and no Firebase project is required. Production code uses
/// [FirebaseAuthDataSourceImpl].
abstract class FirebaseAuthDataSource {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<PhoneVerification> requestPhoneVerification({
    required String phoneNumber,
    int? resendToken,
  });

  Future<AuthUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<PhoneVerification> requestPhoneLink({
    required String phoneNumber,
    required String email,
    required String password,
    int? resendToken,
  });

  Future<AuthUser> verifyPhoneLink({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
  });

  Future<void> cancelPhoneLink();
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  FirebaseAuthDataSourceImpl({required firebase.FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  final firebase.FirebaseAuth _firebaseAuth;

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
          (user) => user == null ? null : _mapUser(user),
        );
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return _requireUser(credential.user);
    } on firebase.FirebaseAuthException catch (error) {
      throw _mapEmailError(error);
    }
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _requireUser(credential.user);
      if (displayName.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(displayName.trim());
        return _mapUser(_firebaseAuth.currentUser ?? credential.user!);
      }
      return user;
    } on firebase.FirebaseAuthException catch (error) {
      throw _mapEmailError(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await cancelPhoneLink();
  }

  static const String _validatorAppName = 'lodbod-phone-password-validator';
  firebase.FirebaseAuth? _validatorAuth;

  /// A second Firebase app used only to prove an email/password and link a
  /// phone without touching the main session.
  Future<firebase.FirebaseAuth> _validator() async {
    final cached = _validatorAuth;
    if (cached != null) return cached;

    core.FirebaseApp? app;
    for (final candidate in core.Firebase.apps) {
      if (candidate.name == _validatorAppName) {
        app = candidate;
        break;
      }
    }
    app ??= await core.Firebase.initializeApp(
      name: _validatorAppName,
      options: core.Firebase.app().options,
    );
    return _validatorAuth = firebase.FirebaseAuth.instanceFor(app: app);
  }

  @override
  Future<PhoneVerification> requestPhoneVerification({
    required String phoneNumber,
    int? resendToken,
  }) {
    final completer = Completer<PhoneVerification>();

    void complete(PhoneVerification value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    void fail(AppException error) {
      if (!completer.isCompleted) completer.completeError(error);
    }

    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        try {
          final result = await _firebaseAuth.signInWithCredential(credential);
          final user = result.user;
          if (user == null) {
            fail(const AuthException(
              'Phone verification succeeded but no session was created. '
              'Please try again.',
            ));
            return;
          }
          complete(PhoneVerification(autoVerifiedUser: _mapUser(user)));
        } on AppException catch (error) {
          fail(error);
        } on firebase.FirebaseAuthException catch (error) {
          fail(AuthException(_messageFor(error)));
        } on Exception {
          fail(const AuthException(
            'Automatic phone verification failed. Enter the code instead.',
          ));
        }
      },
      verificationFailed: (error) => fail(AuthException(_messageFor(error))),
      codeSent: (verificationId, forceResendingToken) {
        complete(
          PhoneVerification(
            verificationId: verificationId,
            resendToken: forceResendingToken,
          ),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        // Auto-retrieval timed out before an SMS arrived. The user can still
        // type the code, so hand the verification ID to the OTP screen.
        complete(PhoneVerification(verificationId: verificationId));
      },
    );

    return completer.future;
  }

  @override
  Future<AuthUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      return _requireUser(result.user);
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  @override
  Future<PhoneVerification> requestPhoneLink({
    required String phoneNumber,
    required String email,
    required String password,
    int? resendToken,
  }) async {
    final validator = await _validator();
    // Prove the password first and make the email account the validator's
    // current user. The session stays open only until the code is linked or
    // the flow is cancelled.
    try {
      await validator.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthException(_messageForPassword(error));
    }

    final completer = Completer<PhoneVerification>();

    void complete(PhoneVerification value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    void fail(AppException error) {
      if (!completer.isCompleted) completer.completeError(error);
    }

    validator.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        try {
          final user = await _completePhoneLink(
            validator: validator,
            credential: credential,
            phoneNumber: phoneNumber,
            email: email,
            password: password,
          );
          complete(PhoneVerification(autoVerifiedUser: user));
        } on AppException catch (error) {
          fail(error);
        } on firebase.FirebaseAuthException catch (error) {
          fail(AuthException(_messageForPhoneLink(error)));
        } on Exception {
          fail(const AuthException(
            'Automatic phone verification failed. Enter the code instead.',
          ));
        }
      },
      verificationFailed: (error) => fail(AuthException(_messageFor(error))),
      codeSent: (verificationId, forceResendingToken) {
        complete(
          PhoneVerification(
            verificationId: verificationId,
            resendToken: forceResendingToken,
          ),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        complete(PhoneVerification(verificationId: verificationId));
      },
    );

    return completer.future;
  }

  @override
  Future<AuthUser> verifyPhoneLink({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
  }) async {
    final validator = await _validator();
    final normalized = email.trim().toLowerCase();
    try {
      final signedInEmail =
          validator.currentUser?.email?.trim().toLowerCase() ?? '';
      if (signedInEmail != normalized) {
        await validator.signInWithEmailAndPassword(
          email: normalized,
          password: password,
        );
      }
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _completePhoneLink(
        validator: validator,
        credential: credential,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
      );
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthException(_messageForPhoneLink(error));
    }
  }

  @override
  Future<void> cancelPhoneLink() async {
    final validator = _validatorAuth;
    if (validator == null) return;
    try {
      await validator.signOut();
    } catch (_) {
      // Cancellation is best effort.
    }
  }

  /// Links [credential] to the email account signed into [validator], then
  /// opens the main session for the same UID.
  Future<AuthUser> _completePhoneLink({
    required firebase.FirebaseAuth validator,
    required firebase.PhoneAuthCredential credential,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final current = validator.currentUser;
    if (current == null) {
      throw const AuthException(
        'Your account session expired. Sign in with email and try again.',
      );
    }

    final hasPhoneProvider = current.providerData.any(
      (p) => p.providerId == 'phone',
    );

    try {
      if (hasPhoneProvider) {
        // The phone provider is already linked to this email account.
        // We MUST reauthenticateWithCredential to force Firebase to validate
        // the smsCode against the verification ID. Calling linkWithCredential
        // would immediately throw 'provider-already-linked' without checking
        // the smsCode.
        await current.reauthenticateWithCredential(credential);
      } else {
        await current.linkWithCredential(credential);
      }
    } on firebase.FirebaseAuthException catch (error) {
      if (error.code == 'provider-already-linked') {
        try {
          await current.reauthenticateWithCredential(credential);
        } on firebase.FirebaseAuthException catch (reauthError) {
          await _signOutValidator(validator);
          throw AuthException(_messageForPhoneLink(reauthError));
        }
      } else {
        await _signOutValidator(validator);
        throw AuthException(_messageForPhoneLink(error));
      }
    }

    await _signOutValidator(validator);

    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return _requireUser(result.user);
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthException(_messageForPassword(error));
    }
  }

  Future<void> _signOutValidator(firebase.FirebaseAuth validator) async {
    try {
      await validator.signOut();
    } catch (_) {
      // The main session result is more important than cleanup.
    }
  }

  AuthUser _requireUser(firebase.User? user) {
    if (user == null) {
      throw const AuthException(AppStrings.invalidCredentials);
    }
    return _mapUser(user);
  }

  AuthUser _mapUser(firebase.User user) {
    final rawEmail = user.email ?? '';
    // Never expose the internal phone-account alias as the user's email.
    final email = PhoneNumber.isAccountEmail(rawEmail) ? '' : rawEmail;
    final phone = user.phoneNumber ?? '';
    final explicitName = user.displayName?.trim() ?? '';
    final fallbackName = explicitName.isNotEmpty
        ? explicitName
        : phone.isNotEmpty
            ? ''
            : email.isEmpty
                ? 'Shipper'
                : email.split('@').first;

    return AuthUser(
      id: user.uid,
      email: email,
      displayName: fallbackName,
      phoneNumber: phone,
    );
  }

  AuthException _mapEmailError(firebase.FirebaseAuthException error) {
    if (_isUnavailable(error)) {
      return AuthServiceUnavailableException(_messageFor(error));
    }
    return AuthException(_messageFor(error));
  }

  bool _isUnavailable(firebase.FirebaseAuthException error) {
    return error.code == 'network-request-failed' ||
        error.code == 'too-many-requests' ||
        error.code == 'operation-not-allowed' ||
        error.code == 'invalid-api-key' ||
        error.code == 'app-not-authorized' ||
        error.code == 'internal-error' ||
        error.code == 'unknown';
  }

  /// Password-specific error messages (login with email/password context).
  String _messageForPassword(firebase.FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.invalidCredentials;
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please wait and try again.';
      default:
        return _messageFor(error);
    }
  }

  /// Phone-link specific error messages (linking phone to existing account).
  String _messageForPhoneLink(firebase.FirebaseAuthException error) {
    switch (error.code) {
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'provider-already-linked':
        return 'A phone number is already linked to this account.';
      case 'invalid-verification-code':
      case 'invalid-credential':
        return 'That code is incorrect. Check it and try again.';
      case 'session-expired':
      case 'invalid-verification-id':
        return 'This verification has expired. Request a new code.';
      default:
        return _messageFor(error);
    }
  }

  String _messageFor(firebase.FirebaseAuthException error) {
    // Firebase reports a blocked destination behind `operation-not-allowed`
    // with a message like "SMS unable to be sent until this region enabled by
    // the app developer." Check the message so the user is not told the whole
    // provider is disabled when only the region policy is.
    final detail = (error.message ?? '').toLowerCase();
    if (detail.contains('billing_not_enabled') ||
        detail.contains('billing not enabled')) {
      return 'This phone number is not in the Firebase test list. Please use a registered test number.';
    }
    if (detail.contains('region')) {
      return 'SMS verification is not available for this region. Please use a registered test number.';
    }

    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number, including the country code.';
      case 'invalid-verification-code':
        return 'That code is incorrect. Check it and try again.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'This verification has expired. Request a new code.';
      case 'missing-verification-code':
        return 'Enter the 6-digit code from the SMS.';
      case 'missing-verification-id':
        return 'Request a new code to continue.';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'Too many verification attempts. Please wait and try again.';
      case 'billing-not-enabled':
        return 'This phone number is not in the Firebase test list. Please use a registered test number.';
      case 'captcha-check-failed':
      case 'missing-client-identifier':
        return 'This device could not complete verification. Try again.';
      case 'network-request-failed':
        return AppStrings.networkError;
      case 'operation-not-allowed':
        return 'This phone number is not in the Firebase test list. Please use a registered test number.';
      case 'app-not-authorized':
      case 'invalid-api-key':
        return 'Firebase is not configured correctly for this app.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.invalidCredentials;
      case 'internal-error':
      case 'unknown':
      default:
        return 'Authentication service is unavailable. Try again.';
    }
  }
}
