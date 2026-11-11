import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/providers/phone_auth_controller.dart';
import 'package:lodbod/features/auth/presentation/screens/registration_screen.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_profile_repository.dart';

void main() {
  const button = 'Create account & verify phone';

  late FakeAuthRepository auth;
  late ProviderContainer container;
  late GoRouter router;

  Future<void> pumpScreen(WidgetTester tester) async {
    router = GoRouter(
      initialLocation: '/register',
      routes: <RouteBase>[
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegistrationScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('OTP screen')),
          ),
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
    await tester.pumpAndSettle();
  }

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await pumpScreen(tester);
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String phone = '9841000000',
    String email = 'aarav@shrestha.com.np',
    String password = 'Shipper123',
    String confirm = 'Shipper123',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Aarav Shrestha');
    await tester.enterText(fields.at(1), phone);
    await tester.enterText(fields.at(2), email);
    await tester.enterText(fields.at(3), password);
    await tester.enterText(fields.at(4), confirm);
    await tester.pumpAndSettle();
  }

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

  testWidgets('shows the +977 prefix and no fake stepper', (tester) async {
    await pumpScreen(tester);

    expect(find.text('+977 '), findsOneWidget);
    expect(find.text('Details'), findsNothing);
    expect(find.text('Verify'), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('lays out without overflow on a narrow phone', (tester) async {
    await pumpAt(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, button), findsOneWidget);
  });

  testWidgets('lays out without overflow on a tablet', (tester) async {
    await pumpAt(tester, const Size(1024, 768));

    expect(tester.takeException(), isNull);
  });

  testWidgets('sends an OTP that links email and phone into one user',
      (tester) async {
    await pumpScreen(tester);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, button));
    await tester.pumpAndSettle();

    expect(auth.lastPhoneNumber, '+9779841000000');
    expect(find.text('OTP screen'), findsOneWidget);

    final verified = await container
        .read(phoneAuthControllerProvider.notifier)
        .verify(FakeAuthRepository.validTestCode);

    expect(verified, isTrue);
    expect(auth.linkedEmail, 'aarav@shrestha.com.np');
    expect(auth.linkedPassword, 'Shipper123');
    expect(auth.linkedDisplayName, 'Aarav Shrestha');
    expect(auth.linkedPhoneNumber, '+9779841000000');

    final user = container.read(authNotifierProvider).valueOrNull;
    expect(user?.email, 'aarav@shrestha.com.np');
    expect(user?.displayName, 'Aarav Shrestha');
    expect(user?.phoneNumber, '+9779841000000');
  });

  testWidgets('blocks submission until every field is filled', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
        find.byType(TextFormField).at(2), 'aarav@shrestha.com.np');
    await tester.enterText(find.byType(TextFormField).at(3), 'Shipper123');
    await tester.enterText(find.byType(TextFormField).at(4), 'Shipper123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, button));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.fieldRequired), findsNWidgets(2));
    expect(auth.lastPhoneNumber, isNull);
  });

  testWidgets('rejects a short password', (tester) async {
    await pumpScreen(tester);
    await fillForm(tester, password: '12345', confirm: '12345');

    await tester.tap(find.widgetWithText(FilledButton, button));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(auth.lastPhoneNumber, isNull);
  });

  testWidgets('rejects mismatched confirm password', (tester) async {
    await pumpScreen(tester);
    await fillForm(tester, confirm: 'Shipper124');

    await tester.tap(find.widgetWithText(FilledButton, button));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordMismatch), findsOneWidget);
    expect(auth.lastPhoneNumber, isNull);
  });

  testWidgets('rejects an invalid phone number', (tester) async {
    await pumpScreen(tester);
    await fillForm(tester, phone: '8812345678');

    await tester.tap(find.widgetWithText(FilledButton, button));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.invalidNepalPhone), findsOneWidget);
    expect(auth.lastPhoneNumber, isNull);
  });
}
