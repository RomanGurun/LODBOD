import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_profile_repository.dart';

void main() {
  const uid = 'phone-uid';
  const phone = '+9779812345678';
  final now = DateTime.utc(2026, 1, 1);

  const phoneUser = AuthUser(
    id: uid,
    email: '',
    displayName: '',
    phoneNumber: phone,
  );

  ProviderContainer containerWith(
    FakeUserProfileRepository profiles, {
    AuthUser? user,
  }) {
    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user ?? phoneUser),
        ),
        userProfileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('restores an existing profile by Firebase UID without creating another',
      () async {
    final existing = UserProfile(
      uid: uid,
      name: 'Sushil Thapa',
      email: '',
      phone: phone,
      role: UserProfile.roleCarrier,
      isPhoneVerified: true,
      createdAt: now,
      updatedAt: now,
    );
    final profiles = FakeUserProfileRepository(
      profiles: <String, UserProfile>{uid: existing},
    );

    final container = containerWith(profiles);
    final profile = await container.read(userProfileProvider.future);

    expect(profile?.name, 'Sushil Thapa');
    expect(profile?.role, UserProfile.roleCarrier);
    expect(profiles.ensureCalls, 1);
    expect(profiles.saveCalls, 0);
    expect(profiles.stored(uid), existing);
  });

  test('creates a minimal profile once when none exists yet', () async {
    final profiles = FakeUserProfileRepository();
    final container = containerWith(profiles);

    final first = await container.read(userProfileProvider.future);

    expect(first?.uid, uid);
    expect(first?.phone, phone);
    expect(first?.isPhoneVerified, isFalse);
    expect(first?.isComplete, isFalse);
    expect(profiles.ensureCalls, 1);

    // Reading the profile again (for example after a refresh) retrieves the
    // same record instead of creating a duplicate.
    final second = await profiles.ensureProfile(
      uid: uid,
      phoneNumber: phone,
    );
    expect(second.uid, uid);
    expect(profiles.ensureCalls, 2);
  });

  test('saving the completion form persists name and role', () async {
    final profiles = FakeUserProfileRepository();
    final container = containerWith(profiles);
    await container.read(userProfileProvider.future);

    final saved = await container.read(userProfileProvider.notifier).save(
          fullName: '  Sushil Thapa  ',
          role: UserProfile.roleCarrier,
        );

    expect(saved.name, 'Sushil Thapa');
    expect(saved.role, UserProfile.roleCarrier);
    expect(saved.isComplete, isTrue);
    expect(saved.isPhoneVerified, isTrue);

    final stored = profiles.stored(uid);
    expect(stored?.name, 'Sushil Thapa');
    expect(stored?.role, UserProfile.roleCarrier);
    expect(profiles.saveCalls, 1);
  });

  test('rejects an empty full name', () async {
    final profiles = FakeUserProfileRepository();
    final container = containerWith(profiles);
    await container.read(userProfileProvider.future);

    expect(
      () => container
          .read(userProfileProvider.notifier)
          .save(fullName: '   ', role: UserProfile.roleShipper),
      throwsA(isA<ValidationException>()),
    );
  });

  test('signing out clears the profile', () async {
    final profiles = FakeUserProfileRepository();
    final container = containerWith(profiles);
    expect(await container.read(userProfileProvider.future), isNotNull);

    await container.read(authNotifierProvider.notifier).signOut();

    expect(container.read(authNotifierProvider).valueOrNull, isNull);
    expect(await container.read(userProfileProvider.future), isNull);
  });

  test('a MockAPI failure is surfaced so the router can offer a retry',
      () async {
    final profiles = FakeUserProfileRepository()..failRequests = true;
    final container = containerWith(profiles);

    await expectLater(
      container.read(userProfileProvider.future),
      throwsA(isA<NetworkException>()),
    );

    profiles.failRequests = false;
    container.invalidate(userProfileProvider);

    final profile = await container.read(userProfileProvider.future);
    expect(profile?.uid, uid);
  });
}
