import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/data/mock/mock_auth_repository.dart';
import 'package:lodbod/features/auth/presentation/screens/login_screen.dart';

void main() {
  late ProviderContainer container;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository(latency: Duration.zero);
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    repository.dispose();
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to the phone tab on a narrow phone', (tester) async {
    await pumpAt(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(
        find.byKey(const ValueKey<String>('auth-tab-phone')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('auth-tab-email')), findsOneWidget);
    expect(find.text('Sign In & Send OTP'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Keep me signed in'), findsNothing);
  });

  testWidgets('shows the email form on the email tab without overflow',
      (tester) async {
    await pumpAt(tester, const Size(320, 568));

    await tester.tap(find.byKey(const ValueKey<String>('auth-tab-email')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Keep me signed in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('fits a tablet without overflow', (tester) async {
    await pumpAt(tester, const Size(1024, 768));

    expect(tester.takeException(), isNull);
  });

  testWidgets('validates the Nepal phone number before sending an OTP',
      (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tester.enterText(find.byType(TextFormField).first, '12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In & Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid 10-digit Nepal mobile number'),
        findsOneWidget);
  });
}
