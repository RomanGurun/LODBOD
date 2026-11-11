import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/presentation/screens/verify_email_screen.dart';

import '../../../support/fake_auth.dart';

void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository(
      user: const AuthUser(
        id: 'user-123',
        email: 'test.shipper@gmail.com',
        displayName: 'Test Shipper',
        isEmailVerified: false,
      ),
    );
    auth.isEmailVerified = false;

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: VerifyEmailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders verify email title, user email, and action buttons',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Verify your Gmail'), findsOneWidget);
    expect(find.textContaining('test.shipper@gmail.com'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "I've verified my email"),
        findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Resend verification email'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextButton, 'Sign out and use another email'),
      findsNothing,
    );
  });

  testWidgets('shows warning SnackBar when email is not yet verified',
      (tester) async {
    await pumpScreen(tester);

    auth.isEmailVerified = false;

    await tester.tap(find.widgetWithText(FilledButton, "I've verified my email"));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text(
        'Email is not verified yet. Please click the link sent to your Gmail inbox.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows success SnackBar when email is verified', (tester) async {
    await pumpScreen(tester);

    auth.isEmailVerified = true;

    await tester.tap(find.widgetWithText(FilledButton, "I've verified my email"));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Email verified successfully!'), findsOneWidget);
  });

  testWidgets('resends verification email and shows confirmation',
      (tester) async {
    await pumpScreen(tester);

    expect(auth.sendEmailVerificationCount, 0);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Resend verification email'),
    );
    await tester.pumpAndSettle();

    expect(auth.sendEmailVerificationCount, 1);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text(
        'Verification email resent. Please check your inbox and spam folder.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not show sign out button on verify email screen',
      (tester) async {
    await pumpScreen(tester);

    expect(
      find.widgetWithText(TextButton, 'Sign out and use another email'),
      findsNothing,
    );
  });
}
