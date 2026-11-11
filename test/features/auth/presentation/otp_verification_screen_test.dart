import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/providers/phone_auth_controller.dart';
import 'package:lodbod/features/auth/presentation/screens/otp_verification_screen.dart';

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

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpVerificationScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> sendOtp() async {
    await container.read(authNotifierProvider.future);
    await container
        .read(phoneAuthControllerProvider.notifier)
        .request(phoneNumber: phone, password: password);
  }

  Future<void> disposeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('verifies the SMS code and creates the Firebase session',
      (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    expect(find.text('Verify your number'), findsOneWidget);
    expect(find.textContaining('+977 98******78'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify & continue'));
    await tester.pumpAndSettle();

    expect(
      container.read(authNotifierProvider).valueOrNull?.phoneNumber,
      phone,
    );
    await disposeScreen(tester);
  });

  testWidgets('shows the Firebase error for a wrong code', (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify & continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('That code is incorrect. Check it and try again.'),
      findsOneWidget,
    );
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
    await disposeScreen(tester);
  });

  testWidgets('rejects a code that is not six digits', (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), '12');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify & continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the 6-digit code'), findsOneWidget);
    await disposeScreen(tester);
  });

  testWidgets('resends with the Firebase resend token after the cooldown',
      (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    expect(find.text('Resend in 30s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Resend code'), findsOneWidget);

    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();

    expect(auth.resendCount, 1);
    expect(auth.lastResendToken, 42);
    await disposeScreen(tester);
  });

  testWidgets('change number leaves the OTP screen', (tester) async {
    await sendOtp();
    final router = GoRouter(
      initialLocation: '/otp',
      routes: <RouteBase>[
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpVerificationScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Change phone number'));
    await tester.pumpAndSettle();

    expect(find.text('Login screen'), findsOneWidget);
    expect(container.read(phoneAuthControllerProvider).phoneNumber, isEmpty);
  });

  testWidgets('asks for a new code when the verification expired',
      (tester) async {
    await container.read(authNotifierProvider.future);
    await pumpScreen(tester);

    expect(
      find.text('This code has expired. Request a new one.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Change phone number'),
      findsOneWidget,
    );
    await disposeScreen(tester);
  });
}
