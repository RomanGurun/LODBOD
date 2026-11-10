import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/data/mock/mock_auth_repository.dart';
import 'package:lodbod/features/auth/providers/auth_notifier.dart';
import 'package:lodbod/shared/providers/repository_providers.dart';

void main() {
  ProviderContainer containerWith(MockAuthRepository repository) {
    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('signs in with the demo account', () async {
    final repository = MockAuthRepository(latency: Duration.zero);
    addTearDown(repository.dispose);
    final container = containerWith(repository);
    await container.read(authNotifierProvider.future);

    await container.read(authNotifierProvider.notifier).signIn(
          email: 'demo@lodbod.com',
          password: 'Demo@1234',
        );

    expect(
      container.read(authNotifierProvider).valueOrNull?.email,
      'demo@lodbod.com',
    );
  });

  test('surfaces invalid credentials as an error', () async {
    final repository = MockAuthRepository(latency: Duration.zero);
    addTearDown(repository.dispose);
    final container = containerWith(repository);
    await container.read(authNotifierProvider.future);

    await container.read(authNotifierProvider.notifier).signIn(
          email: 'demo@lodbod.com',
          password: 'wrong-password',
        );

    final state = container.read(authNotifierProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AuthException>());
  });

  test('signs up a new shipper and signs them in', () async {
    final repository = MockAuthRepository(latency: Duration.zero);
    addTearDown(repository.dispose);
    final container = containerWith(repository);
    await container.read(authNotifierProvider.future);

    await container.read(authNotifierProvider.notifier).signUp(
          email: 'aarav@shrestha.com.np',
          password: 'Shipper123',
          displayName: 'Aarav Shrestha',
        );

    final user = container.read(authNotifierProvider).valueOrNull;
    expect(user?.email, 'aarav@shrestha.com.np');
    expect(user?.displayName, 'Aarav Shrestha');
  });

  test('signUp surfaces weak passwords as an error', () async {
    final repository = MockAuthRepository(latency: Duration.zero);
    addTearDown(repository.dispose);
    final container = containerWith(repository);
    await container.read(authNotifierProvider.future);

    await container.read(authNotifierProvider.notifier).signUp(
          email: 'aarav@shrestha.com.np',
          password: '12345',
          displayName: 'Aarav Shrestha',
        );

    final state = container.read(authNotifierProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AuthException>());
    expect(state.error.toString(), contains('6'));
  });

  test('signOut clears the current user', () async {
    final repository = MockAuthRepository(latency: Duration.zero);
    addTearDown(repository.dispose);
    final container = containerWith(repository);
    await container.read(authNotifierProvider.future);
    await container.read(authNotifierProvider.notifier).signIn(
          email: 'demo@lodbod.com',
          password: 'Demo@1234',
        );

    await container.read(authNotifierProvider.notifier).signOut();

    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });
}
