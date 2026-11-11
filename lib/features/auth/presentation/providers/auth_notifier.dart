import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/core/di/repository_providers.dart';

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.authStateChanges().listen((user) {
      // Repositories emit their current user right after subscribing and
      // re-emit the new user after signIn/signUp/signOut, which this
      // notifier already reflects through its own state updates.
      // Re-emitting an unchanged value would needlessly notify dependents
      // (Riverpod cancels their in-flight builds on invalidation), so only
      // genuine external changes are propagated — never echoes, and never a
      // value racing a load that is still in flight.
      if (state.valueOrNull == user) return;
      if (state.isLoading) return;
      state = AsyncData<AuthUser?>(user);
    });
    ref.onDispose(subscription.cancel);
    return repository.currentUser;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading<AuthUser?>();
    final repository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard<AuthUser?>(
      () => repository.signIn(email: email, password: password),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String phone = '',
  }) async {
    state = const AsyncLoading<AuthUser?>();
    final repository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard<AuthUser?>(() async {
      final user = await repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _saveProfile(user, phone: phone);
      return user;
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    state = const AsyncLoading<AuthUser?>();
    final repository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard<AuthUser?>(() async {
      await repository.signOut();
      return null;
    });
  }

  /// Writes the Firestore profile document `users/{uid}` for a newly
  /// registered shipper. Failures are absorbed by the resilient profile
  /// repository (in-memory fallback), never blocking sign-up itself.
  Future<void> _saveProfile(AuthUser user, {required String phone}) async {
    final profiles = ref.read(userProfileRepositoryProvider);
    final now = DateTime.now();
    await profiles.saveProfile(
      UserProfile(
        uid: user.id,
        name: user.displayName,
        email: user.email,
        phone: phone.trim(),
        role: 'shipper',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

/// Firestore profile of the signed-in shipper (see `users/{uid}`), or a
/// profile synthesized from the auth identity when none was stored.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = await ref.watch(authNotifierProvider.future);
  if (user == null) return null;

  final repository = ref.watch(userProfileRepositoryProvider);
  final stored = await repository.getProfile(user.id);
  if (stored != null) return stored;

  // Missing profile is handled safely: fall back to auth identity data.
  return UserProfile(
    uid: user.id,
    name: user.displayName,
    email: user.email,
    phone: '',
    role: 'shipper',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
});
