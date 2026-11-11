import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
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

  final profile = UserProfile(
    uid: 'user-1',
    name: 'Aarav Shrestha',
    email: 'aarav@shrestha.com.np',
    phone: phone,
    role: 'shipper',
    isPhoneVerified: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    auth = FakeAuthRepository.signedOut();
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(
          FakeUserProfileRepository(profiles: {profile.uid: profile}),
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

  Future<void> enterCode(WidgetTester tester, String code) async {
    for (var i = 0; i < code.length && i < 6; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), code[i]);
    }
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

    await enterCode(tester, '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify & continue'));
    await tester.pumpAndSettle();

    expect(
      container.read(authNotifierProvider).valueOrNull?.phoneNumber,
      phone,
    );
    await disposeScreen(tester);
  });

  testWidgets(
      'pasting a 6-digit code into the first box distributes across all boxes',
      (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, '654321');
    await tester.pump();

    for (var i = 0; i < 6; i++) {
      final field =
          tester.widget<TextFormField>(find.byType(TextFormField).at(i));
      expect(field.controller?.text, '${6 - i}');
    }
    await disposeScreen(tester);
  });

  testWidgets('shows the Firebase error and deletes all digits for a wrong code',
      (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    await enterCode(tester, '000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify & continue'));
    await tester.pumpAndSettle();

    // Prompts user with the failed/incorrect code error message
    expect(
      find.text('That code is incorrect. Check it and try again.'),
      findsOneWidget,
    );
    // Deletes all 6 individual OTP input boxes so they are emptied
    for (var i = 0; i < 6; i++) {
      final field =
          tester.widget<TextFormField>(find.byType(TextFormField).at(i));
      expect(field.controller?.text, isEmpty);
    }

    expect(container.read(authNotifierProvider).valueOrNull, isNull);
    await disposeScreen(tester);
  });

  testWidgets('rejects a code that is not six digits', (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    await enterCode(tester, '12');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify & continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the 6-digit code'), findsOneWidget);
    await disposeScreen(tester);
  });

  testWidgets(
      'does not display back button, resend code, or change phone number',
      (tester) async {
    await sendOtp();
    await pumpScreen(tester);

    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('Resend code'), findsNothing);
    expect(find.textContaining('Resend in'), findsNothing);
    expect(find.text('Change phone number'), findsNothing);
    await disposeScreen(tester);
  });

  testWidgets(
      'renders 6 responsive boxes on narrow 320px screens without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await sendOtp();
    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Verify your number'), findsOneWidget);
    // Verifies 6 individual boxes are rendered
    expect(find.byType(TextFormField), findsNWidgets(6));
    await disposeScreen(tester);
  });

  testWidgets('expired session allows navigating back to sign in',
      (tester) async {
    await container.read(authNotifierProvider.future);
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

    await tester.tap(find.widgetWithText(FilledButton, 'Back to Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Login screen'), findsOneWidget);
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
      find.widgetWithText(FilledButton, 'Back to Sign In'),
      findsOneWidget,
    );
    await disposeScreen(tester);
  });
}
