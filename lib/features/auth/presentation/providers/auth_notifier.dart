import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/errors/app_exception.dart';
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

  /// Adopts a session created outside [signIn]/[signUp] — Firebase phone
  /// auto-verification completes on the datasource before this notifier sees
  /// it.
  void adoptUser(AuthUser user) {
    state = AsyncData<AuthUser?>(user);
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

  Future<void> sendEmailVerification() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.sendEmailVerification();
  }

  Future<AuthUser> reloadUser() async {
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.reloadUser();
    state = AsyncData<AuthUser?>(user);
    return user;
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

  /// Best-effort profile seed for email registration.
  ///
  /// The profile provider performs the authoritative get-or-create afterwards;
  /// a profile write failure must never turn a successful sign-up into an
  /// error, because the user is already authenticated and can retry safely.
  Future<void> _saveProfile(AuthUser user, {required String phone}) async {
    final profiles = ref.read(userProfileRepositoryProvider);
    final now = DateTime.now();
    try {
      await profiles.saveProfile(
        UserProfile(
          uid: user.id,
          name: user.displayName,
          email: user.email,
          phone: phone.trim(),
          isPhoneVerified: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } on AppException {
      // The completion screen offers a retry; the Firebase session is intact.
    } catch (_) {
      // Same as above: never block authentication on profile persistence.
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

/// Alias for [authNotifierProvider] under the name used in the auth spec.
///
/// Both names expose the same `AsyncValue<AuthUser?>`, so widgets can watch
/// either one without creating a second source of truth.
final authStateProvider = authNotifierProvider;

/// Profile for the signed-in user, loaded from MockAPI `/users`.
///
/// On every session it resolves the profile by Firebase UID and creates a
/// minimal record only when none exists. Because this provider watches the
/// auth state, signing out clears the profile and signing in restores (or
/// creates) it without ever duplicating an existing record.
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = await ref.watch(authNotifierProvider.future);
    if (user == null) return null;

    final repository = ref.watch(userProfileRepositoryProvider);
    return repository.ensureProfile(
      uid: user.id,
      phoneNumber: user.phoneNumber,
      fullName: user.displayName,
      email: user.email,
    );
  }

  /// Persists the completion form and updates the in-memory state so the
  /// router can leave the completion screen immediately.
  Future<UserProfile> save({
    required String fullName,
    required String role,
  }) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      throw const AuthException('Your session expired. Please sign in again.');
    }

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationException('Please enter your full name.');
    }

    final existing = state.valueOrNull;
    final now = DateTime.now();
    final base = existing ??
        UserProfile(
          uid: user.id,
          name: '',
          email: user.email,
          phone: user.phoneNumber,
          createdAt: now,
          updatedAt: now,
        );

    final profile = base.copyWith(
      name: trimmedName,
      role: UserProfile.normalizeRole(role),
      isPhoneVerified:
          base.isPhoneVerified || user.phoneNumber.trim().isNotEmpty,
      updatedAt: now,
    );

    await ref.read(userProfileRepositoryProvider).saveProfile(profile);
    state = AsyncData<UserProfile?>(profile);
    return profile;
  }
}

final userProfileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);
