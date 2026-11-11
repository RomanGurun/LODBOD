import 'dart:async';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/phone_verification.dart';
import 'package:lodbod/features/auth/domain/repositories/i_auth_repository.dart';

class MockAuthRepository implements IAuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 350)});

  static const AuthUser _demoUser = AuthUser(
    id: 'demo-1',
    email: AppStrings.demoEmail,
    displayName: 'Aarav Shrestha',
    isEmailVerified: true,
  );

  final Duration latency;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  final Set<String> _registeredEmails = <String>{AppStrings.demoEmail};

  /// Allows tests or mock flows to toggle email verified state.
  bool mockEmailVerified = false;

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);

    final normalized = email.trim().toLowerCase();
    if (normalized == AppStrings.demoEmail &&
        password == AppStrings.demoPassword) {
      _currentUser = _demoUser;
      _controller.add(_currentUser);
      return _demoUser;
    }
    throw const AuthException(AppStrings.invalidCredentials);
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future<void>.delayed(latency);

    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw const AuthException(AppStrings.invalidEmail);
    }
    if (password.length < 6) {
      throw const AuthException(AppStrings.passwordTooShort);
    }
    if (_registeredEmails.contains(normalized)) {
      throw const AuthException('An account with this email already exists.');
    }

    final user = AuthUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: normalized,
      displayName: displayName.trim().isEmpty ? 'Shipper' : displayName.trim(),
      isEmailVerified: mockEmailVerified,
    );
    _registeredEmails.add(normalized);
    _currentUser = user;
    _controller.add(_currentUser);
    return user;
  }

  @override
  Future<void> sendEmailVerification() async {
    await Future<void>.delayed(latency);
  }

  @override
  Future<AuthUser> reloadUser() async {
    await Future<void>.delayed(latency);
    if (_currentUser == null) {
      throw const AuthException('No user is currently signed in.');
    }
    _currentUser = _currentUser!.copyWith(isEmailVerified: mockEmailVerified);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(latency);
    // The demo store has no mail transport — never pretend an email was sent.
    throw const AuthException(
      'Password reset is not available for demo accounts. '
      'Register a Firebase account to use this feature.',
    );
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(latency);
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<PhoneVerification> requestPhoneVerification({
    required String phoneNumber,
    int? resendToken,
  }) async {
    // The demo store has no SMS transport. Never pretend a code was sent.
    throw const AuthException(
      'Phone sign-in requires Firebase. Configure the Firebase project to use '
      'phone authentication, then try again.',
    );
  }

  @override
  Future<AuthUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    throw const AuthException(
      'Phone sign-in requires Firebase. Configure the Firebase project to use '
      'phone authentication, then try again.',
    );
  }

  @override
  Future<PhoneVerification> requestPhoneLink({
    required String phoneNumber,
    required String email,
    required String password,
    int? resendToken,
  }) async {
    throw const AuthException(
      'Phone sign-in requires Firebase. Configure the Firebase project to use '
      'phone authentication, then try again.',
    );
  }

  @override
  Future<AuthUser> verifyPhoneLink({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      'Phone sign-in requires Firebase. Configure the Firebase project to use '
      'phone authentication, then try again.',
    );
  }

  @override
  Future<void> cancelPhoneLink() async {}

  @override
  Future<void> deleteCurrentUser() async {
    await Future<void>.delayed(latency);
    if (_currentUser != null) {
      _registeredEmails.remove(_currentUser!.email);
    }
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
