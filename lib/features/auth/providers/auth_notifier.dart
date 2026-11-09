import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/auth_user.dart';
import '../../../shared/providers/repository_providers.dart';

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.authStateChanges().listen((user) {
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
  }) async {
    state = const AsyncLoading<AuthUser?>();
    final repository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard<AuthUser?>(
      () => repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading<AuthUser?>();
    final repository = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard<AuthUser?>(() async {
      await repository.signOut();
      return null;
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);
