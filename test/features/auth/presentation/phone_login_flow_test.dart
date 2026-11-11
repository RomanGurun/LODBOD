import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/screens/login_screen.dart';
import 'package:lodbod/features/auth/presentation/screens/otp_verification_screen.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_profile_repository.dart';

void main() {
  const phone = '9812345678';

  late FakeAuthRepository auth;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    auth = FakeAuthRepository.signedOut();
    final profile = UserProfile(
      uid: 'user-1',
      name: 'Aarav Shrestha',
      email: 'aarav@shrestha.com.np',
      phone: '+977$phone',
      role: 'shipper',
      isPhoneVerified: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(
          FakeUserProfileRepository(profiles: {profile.uid: profile}),
        ),
      ],
    );
    router = GoRouter(
      initialLocation: '/login',
      routes: <RouteBase>[
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpVerificationScreen(),
        ),
      ],
    );
  });

  tearDown(() {
    router.dispose();
    container.dispose();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390, 844) * 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sends the OTP in E.164 after entering password', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), phone);
    await tester.enterText(find.byType(TextFormField).at(1), 'Shipper123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In & Send OTP'));
    await tester.pumpAndSettle();

    expect(auth.lastPhoneNumber, '+9779812345678');
    expect(find.text('Verify your number'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Android auto-verification skips the code screen',
      (tester) async {
    auth.autoVerifyNext = true;
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), phone);
    await tester.enterText(find.byType(TextFormField).at(1), 'Shipper123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In & Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your number'), findsNothing);
    expect(
      container.read(authNotifierProvider).valueOrNull?.phoneNumber,
      '+9779812345678',
    );
  });

  testWidgets('rejects an invalid number without contacting Firebase',
      (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In & Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid 10-digit Nepal mobile number'),
        findsOneWidget);
    expect(auth.lastPhoneNumber, isNull);
  });
}
