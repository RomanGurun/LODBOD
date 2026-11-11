import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/providers/phone_auth_controller.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_profile_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
  late ProviderContainer container;

  const phone = '+9779812345678';
  const email = 'aarav@shrestha.com.np';
  const password = 'Test@1234';

  final profile = UserProfile(
    uid: 'user-1',
    name: 'Aarav Shrestha',
    email: email,
    phone: phone,
    role: 'shipper',
    isPhoneVerified: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    auth = FakeAuthRepository.signedOut();
    profiles = FakeUserProfileRepository(
      profiles: {profile.uid: profile},
    );
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> init() => container.read(authNotifierProvider.future);

  test('phone login requires a password before sending an OTP', () async {
    await init();

    final result = await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: phone);

    expect(result, isNull);
    expect(auth.lastPhoneNumber, isNull);
    expect(
      container.read(phoneAuthControllerProvider).error,
      'Enter your password to continue.',
    );
  });

  test('phone login rejects numbers with no registered account', () async {
    await init();

    final result = await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: '+9779800000000', password: password);

    expect(result, isNull);
    expect(auth.lastPhoneNumber, isNull);
    expect(
      container.read(phoneAuthControllerProvider).error,
      'No account found for this number. Create an account first.',
    );
  });

  test('requests an OTP and stores the verification session in memory',
      () async {
    await init();

    final result = await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: phone, password: password);

    expect(result, isNotNull);
    expect(auth.lastPhoneNumber, phone);
    final state = container.read(phoneAuthControllerProvider);
    expect(state.phoneNumber, phone);
    expect(state.verificationId, isNotEmpty);
    expect(state.resendToken, 42);
    expect(state.error, isNull);
    expect(state.autoVerified, isFalse);
  });

  test('a valid code creates the authenticated session and links phone',
      () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(phoneNumber: phone, password: password);

    final verified = await controller.verify(FakeAuthRepository.validTestCode);

    expect(verified, isTrue);
    final user = container.read(authNotifierProvider).valueOrNull;
    expect(user?.phoneNumber, phone);
    expect(auth.linkedPhoneNumber, phone);
    expect(container.read(phoneAuthControllerProvider).autoVerified, isTrue);
  });

  test('an invalid code surfaces a readable error and keeps the session',
      () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(phoneNumber: phone, password: password);

    final verified = await controller.verify('000000');

    expect(verified, isFalse);
    expect(
      container.read(phoneAuthControllerProvider).error,
      'That code is incorrect. Check it and try again.',
    );
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  test('rejects a code that is not six digits before calling Firebase',
      () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(phoneNumber: phone, password: password);

    expect(await controller.verify('12'), isFalse);
    expect(
      container.read(phoneAuthControllerProvider).error,
      'Enter the 6-digit code from the SMS.',
    );
  });

  test('resend reuses the Firebase resend token', () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(phoneNumber: phone, password: password);

    await controller.request(phoneNumber: phone, resend: true);

    expect(auth.resendCount, 1);
    expect(auth.lastResendToken, 42);
  });

  test('Android auto-verification adopts the session without a code', () async {
    await init();
    auth.autoVerifyNext = true;

    final result = await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: phone, password: password);

    expect(result?.autoVerifiedUser, isNotNull);
    expect(container.read(phoneAuthControllerProvider).autoVerified, isTrue);
    expect(
      container.read(authNotifierProvider).valueOrNull?.phoneNumber,
      phone,
    );
  });

  test('clear resets the transient verification state', () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(phoneNumber: phone, password: password);

    controller.clear();

    final state = container.read(phoneAuthControllerProvider);
    expect(state.phoneNumber, isEmpty);
    expect(state.verificationId, isNull);
  });
}
