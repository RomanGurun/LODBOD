import 'dart:async';

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/i_auth_repository.dart';

class MockAuthRepository implements IAuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 350)});

  static const AuthUser _demoUser = AuthUser(
    id: 'demo-1',
    email: AppStrings.demoEmail,
    displayName: 'Demo Shipper',
  );

  final Duration latency;
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

    final user = AuthUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: normalized,
      displayName: displayName.trim().isEmpty ? 'Shipper' : displayName.trim(),
    );
    _currentUser = user;
    _controller.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(latency);
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
