import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/providers/phone_auth_controller.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_profile_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  const phone = '+9779812345678';
  const password = 'Test@1234';

  setUp(() {
    auth = FakeAuthRepository.signedOut();
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(
          FakeUserProfileRepository(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> init() => container.read(authNotifierProvider.future);

  test('requests an OTP and stores the verification session in memory',
      () async {
    await init();

    final result = await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: phone);

    expect(result, isNotNull);
    expect(auth.lastPhoneNumber, phone);
    final state = container.read(phoneAuthControllerProvider);
    expect(state.phoneNumber, phone);
    expect(state.verificationId, isNotEmpty);
    expect(state.resendToken, 42);
    expect(state.error, isNull);
    expect(state.autoVerified, isFalse);
  });

  test('a valid code creates the authenticated session', () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(phoneNumber: phone, password: password);

    final verified = await controller.verify(FakeAuthRepository.validTestCode);

    expect(verified, isTrue);
    final user = container.read(authNotifierProvider).valueOrNull;
    expect(user?.id, 'phone-uid');
    expect(user?.phoneNumber, phone);
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
        .request(phoneNumber: phone);

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
    await controller.request(phoneNumber: phone);

    controller.clear();

    final state = container.read(phoneAuthControllerProvider);
    expect(state.phoneNumber, isEmpty);
    expect(state.verificationId, isNull);
  });

  test('phone login sends an OTP without a password', () async {
    await init();

    final result = await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: phone);

    expect(result, isNotNull);
    expect(auth.lastPhoneNumber, phone);
    expect(auth.linkedPassword, isNull);
  });

  test('registration requires a password before sending an OTP', () async {
    await init();

    final result = await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: phone, register: true);

    expect(result, isNull);
    expect(auth.lastPhoneNumber, isNull);
    expect(
      container.read(phoneAuthControllerProvider).error,
      'Enter a password to create an account.',
    );
  });

  test('registration attaches the password after verifying the code', () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(
      phoneNumber: phone,
      password: password,
      register: true,
    );

    final verified = await controller.verify(FakeAuthRepository.validTestCode);

    expect(verified, isTrue);
    expect(auth.linkedPassword, password);
    expect(auth.linkedPhoneNumber, phone);
  });

  test('resending during registration keeps the password for auto-verification',
      () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);
    await controller.request(
      phoneNumber: phone,
      password: password,
      register: true,
    );

    auth.autoVerifyNext = true;
    await controller.request(phoneNumber: phone, resend: true);

    expect(auth.linkedPassword, password);
    expect(auth.linkedPhoneNumber, phone);
  });

  test('email registration links phone and email into the same account',
      () async {
    await init();
    final controller = container.read(phoneAuthControllerProvider.notifier);

    await controller.request(
      phoneNumber: phone,
      password: password,
      register: true,
      email: 'aarav@shrestha.com.np',
      displayName: 'Aarav Shrestha',
    );
    final verified = await controller.verify(FakeAuthRepository.validTestCode);

    expect(verified, isTrue);
    expect(auth.linkedEmail, 'aarav@shrestha.com.np');
    expect(auth.linkedPassword, password);
    expect(auth.linkedDisplayName, 'Aarav Shrestha');

    final user = container.read(authNotifierProvider).valueOrNull;
    expect(user?.email, 'aarav@shrestha.com.np');
    expect(user?.displayName, 'Aarav Shrestha');
    expect(user?.phoneNumber, phone);
  });
}
