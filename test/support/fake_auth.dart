import 'dart:async';

import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/repositories/i_auth_repository.dart';

/// Test double for [IAuthRepository] that starts signed in as [user].
///
/// Defaults to the demo owner (`demo-1`) that owns the seeded sample
/// shipments, matching [ShipmentOwnership.demoOwnerUid]. Use
/// [FakeAuthRepository.signedOut] to model an unauthenticated session.
class FakeAuthRepository implements IAuthRepository {
  FakeAuthRepository({AuthUser? user}) : _user = user ?? demoOwner;

  FakeAuthRepository.signedOut() : _user = null;

  static const AuthUser demoOwner = AuthUser(
    id: 'demo-1',
    email: 'demo@lodbod.com',
    displayName: 'Aarav Shrestha',
  );

  AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (_user == null) {
      throw const AuthException('No user signed in to the fake repository.');
    }
    return _user!;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _user = AuthUser(id: 'new-uid', email: email, displayName: displayName);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
