import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/i_auth_repository.dart';

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
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(AppStrings.invalidCredentials);
      }
      final mapped = _mapUser(user);
      _emit(mapped);
      return mapped;
    } on firebase.FirebaseAuthException {
      return _fallbackSignIn(email: email, password: password);
    } on AuthException {
      rethrow;
    } on Exception {
      return _fallbackSignIn(email: email, password: password);
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
  }) async {
    try {
      final user = await _fallback.signIn(email: email, password: password);
      _emit(user);
      return user;
    } on AuthException {
      throw const AuthException(AppStrings.invalidCredentials);
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
    return AppStrings.invalidCredentials;
  }

  void dispose() => _controller.close();
}
