import 'dart:async';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/phone_verification.dart';
import 'package:lodbod/features/auth/domain/repositories/i_auth_repository.dart';

/// [IAuthRepository] backed by Firebase Auth.
///
/// Email authentication keeps the local demo fallback so the documented
/// showcase still works when Firebase is unreachable. Phone OTP never falls
/// back: a code must be verified by Firebase, and failures are reported to the
/// user instead of being faked.
class FirebaseAuthRepository implements IAuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuthDataSource dataSource,
    required IAuthRepository fallback,
  })  : _dataSource = dataSource,
        _fallback = fallback {
    _currentUser = dataSource.currentUser;
    _subscription = dataSource.authStateChanges().listen(_onExternalChange);
  }

  final FirebaseAuthDataSource _dataSource;
  final IAuthRepository _fallback;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  StreamSubscription<AuthUser?>? _subscription;
  AuthUser? _currentUser;

  /// True while a phone verification is running. Firebase signs the phone user
  /// in before the optional email/password link completes; suppressing those
  /// intermediate events keeps the router from resolving a half-built account
  /// (for example, a profile without the email address).
  bool _phoneFlowActive = false;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  /// Forwards genuine Firebase-side changes (session restored, token revoked,
  /// signed out elsewhere). Echoes of our own writes are ignored.
  void _onExternalChange(AuthUser? user) {
    if (_phoneFlowActive) return;
    if (user == _currentUser) return;
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    // The demo account owns the seeded sample shipments and is authenticated
    // locally by design, so the documented demo journey works even when
    // Firebase is unreachable.
    final normalized = email.trim().toLowerCase();
    if (normalized == AppStrings.demoEmail &&
        password == AppStrings.demoPassword) {
      return _fallbackSignIn(email: email, password: password);
    }

    try {
      final user = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      _emit(user);
      return user;
    } on AuthServiceUnavailableException {
      return _fallbackSignIn(
        email: email,
        password: password,
        unavailableMessage:
            'Authentication service is unavailable. Please try again.',
      );
    } on AuthException {
      rethrow;
    } on Exception {
      return _fallbackSignIn(
        email: email,
        password: password,
        unavailableMessage:
            'Authentication service is unavailable. Please try again.',
      );
    }
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _dataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _emit(user);
      return user;
    } on AuthServiceUnavailableException {
      return _fallbackSignUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    } on AuthException {
      rethrow;
    } on Exception {
      return _fallbackSignUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _dataSource.sendEmailVerification();
    } on AuthException {
      rethrow;
    } catch (error) {
      throw AuthException(
        'Failed to send verification email. Please check your connection and try again.',
      );
    }
  }

  @override
  Future<AuthUser> reloadUser() async {
    try {
      final user = await _dataSource.reloadUser();
      _emit(user);
      return user;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw AuthException(
        'Failed to refresh user status. Please check your connection and try again.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _dataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<PhoneVerification> requestPhoneVerification({
    required String phoneNumber,
    int? resendToken,
  }) async {
    _phoneFlowActive = true;
    try {
      final result = await _dataSource.requestPhoneVerification(
        phoneNumber: phoneNumber,
        resendToken: resendToken,
      );
      // Android auto-verification completes inside the request; publish the
      // final user now.
      final autoUser = result.autoVerifiedUser;
      if (autoUser != null) _emit(autoUser);
      return result;
    } finally {
      _phoneFlowActive = false;
    }
  }

  @override
  Future<AuthUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    _phoneFlowActive = true;
    try {
      final user = await _dataSource.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _emit(user);
      return user;
    } finally {
      _phoneFlowActive = false;
    }
  }

  @override
  Future<PhoneVerification> requestPhoneLink({
    required String phoneNumber,
    required String email,
    required String password,
    int? resendToken,
  }) async {
    _phoneFlowActive = true;
    try {
      final result = await _dataSource.requestPhoneLink(
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        resendToken: resendToken,
      );
      final autoUser = result.autoVerifiedUser;
      if (autoUser != null) _emit(autoUser);
      return result;
    } finally {
      _phoneFlowActive = false;
    }
  }

  @override
  Future<AuthUser> verifyPhoneLink({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
  }) async {
    _phoneFlowActive = true;
    try {
      final user = await _dataSource.verifyPhoneLink(
        phoneNumber: phoneNumber,
        verificationId: verificationId,
        smsCode: smsCode,
        email: email,
        password: password,
      );
      _emit(user);
      return user;
    } finally {
      _phoneFlowActive = false;
    }
  }

  @override
  Future<void> cancelPhoneLink() => _dataSource.cancelPhoneLink();

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } catch (_) {
      // The local fallback still needs to be cleared.
    }
    try {
      await _fallback.signOut();
    } catch (_) {
      // Sign-out should be idempotent even if no fallback user exists.
    }
    _emit(null);
  }

  Future<AuthUser> _fallbackSignIn({
    required String email,
    required String password,
    String? unavailableMessage,
  }) async {
    try {
      final user = await _fallback.signIn(email: email, password: password);
      _emit(user);
      return user;
    } on AuthException {
      throw AuthException(unavailableMessage ?? AppStrings.invalidCredentials);
    }
  }

  Future<AuthUser> _fallbackSignUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = await _fallback.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    _emit(user);
    return user;
  }

  void _emit(AuthUser? user) {
    final changed = _currentUser != user;
    _currentUser = user;
    if (changed) _controller.add(user);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
