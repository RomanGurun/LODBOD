import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/data/mock/mock_auth_repository.dart';
import 'package:lodbod/features/auth/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/screens/registration_screen.dart';
import 'package:lodbod/shared/providers/repository_providers.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RegistrationScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(latency: Duration.zero),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  testWidgets('creates a shipper account from the form', (tester) async {
    await pumpScreen(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Aarav Shrestha');
    await tester.enterText(fields.at(1), '9841000000');
    await tester.enterText(fields.at(2), 'aarav@shrestha.com.np');
    await tester.enterText(fields.at(3), 'Shipper123');
    await tester.enterText(fields.at(4), 'Shipper123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    final user = container.read(authNotifierProvider).valueOrNull;
    expect(user?.email, 'aarav@shrestha.com.np');
    expect(user?.displayName, 'Aarav Shrestha');
  });

  testWidgets('blocks submission until every field is filled', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
        find.byType(TextFormField).at(2), 'aarav@shrestha.com.np');
    await tester.enterText(find.byType(TextFormField).at(3), 'Shipper123');
    await tester.enterText(find.byType(TextFormField).at(4), 'Shipper123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.fieldRequired), findsNWidgets(2));
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  testWidgets('rejects a short password', (tester) async {
    await pumpScreen(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Aarav Shrestha');
    await tester.enterText(fields.at(1), '9841000000');
    await tester.enterText(fields.at(2), 'aarav@shrestha.com.np');
    await tester.enterText(fields.at(3), '12345');
    await tester.enterText(fields.at(4), '12345');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  testWidgets('rejects mismatched confirm password', (tester) async {
    await pumpScreen(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Aarav Shrestha');
    await tester.enterText(fields.at(1), '9841000000');
    await tester.enterText(fields.at(2), 'aarav@shrestha.com.np');
    await tester.enterText(fields.at(3), 'Shipper123');
    await tester.enterText(fields.at(4), 'Shipper124');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordMismatch), findsOneWidget);
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  testWidgets('rejects an invalid phone number', (tester) async {
    await pumpScreen(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Aarav Shrestha');
    await tester.enterText(fields.at(1), 'not-a-phone');
    await tester.enterText(fields.at(2), 'aarav@shrestha.com.np');
    await tester.enterText(fields.at(3), 'Shipper123');
    await tester.enterText(fields.at(4), 'Shipper123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.invalidPhone), findsOneWidget);
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });
}
