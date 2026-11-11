import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/repositories/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  FirebaseAuthRepository({
    required firebase.FirebaseAuth firebaseAuth,
    required IAuthRepository fallback,
  })  : _firebaseAuth = firebaseAuth,
        _fallback = fallback {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      _currentUser = _mapUser(user);
    }
  }

  final firebase.FirebaseAuth _firebaseAuth;
  final IAuthRepository _fallback;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

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
    // The demo account owns the seeded sample shipments and is
    // authenticated locally by design, so the documented demo journey
    // works even when Firebase is unreachable.
    final normalized = email.trim().toLowerCase();
    if (normalized == AppStrings.demoEmail &&
        password == AppStrings.demoPassword) {
      return _fallbackSignIn(email: email, password: password);
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(AppStrings.invalidCredentials);
      }
      final mapped = _mapUser(user);
      _emit(mapped);
      return mapped;
    } on firebase.FirebaseAuthException catch (error) {
      // Client-side failures (wrong password, unknown user, …) must not
      // silently fall back to the local account store.
      if (_isUnavailable(error)) {
        return _fallbackSignIn(
          email: email,
          password: password,
          unavailableMessage:
              'Authentication service is unavailable. Please try again.',
        );
      }
      throw AuthException(_messageFor(error));
    } on AuthException {
      rethrow;
    } on Exception {
      // Firebase itself could not be reached/initialized at all.
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
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(AppStrings.invalidCredentials);
      }
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      final mapped = _mapUser(user);
      _emit(mapped);
      return mapped;
    } on firebase.FirebaseAuthException catch (error) {
      if (_isUnavailable(error)) {
        return _fallbackSignUp(
          email: email,
          password: password,
          displayName: displayName,
        );
      }
      throw AuthException(_messageFor(error));
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
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    } on Exception {
      throw const AuthException(
        'Password reset is unavailable right now. Please try again later.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
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
    _currentUser = user;
    _controller.add(user);
  }

  AuthUser _mapUser(firebase.User user) {
    final email = user.email ?? '';
    final displayName = user.displayName?.trim();
    return AuthUser(
      id: user.uid,
      email: email,
      displayName: displayName == null || displayName.isEmpty
          ? (email.isEmpty ? 'Shipper' : email.split('@').first)
          : displayName,
    );
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

  String _messageFor(firebase.FirebaseAuthException error) {
    if (_isUnavailable(error)) {
      return 'Authentication service is unavailable. Try again.';
    }
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      default:
        return AppStrings.invalidCredentials;
    }
  }

  void dispose() => _controller.close();
}
