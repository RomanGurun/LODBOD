import '../entities/auth_user.dart';

abstract class IAuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();
}
