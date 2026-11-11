import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lodbod/core/di/repository_providers.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/presentation/screens/profile_completion_screen.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_profile_repository.dart';

void main() {
  const uid = 'phone-uid';
  const phone = '+9779812345678';
  const phoneUser = AuthUser(
    id: uid,
    email: '',
    displayName: '',
    phoneNumber: phone,
  );

  late FakeUserProfileRepository profiles;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    profiles = FakeUserProfileRepository();
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: phoneUser),
        ),
        userProfileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
    router = GoRouter(
      initialLocation: '/complete-profile',
      routes: <RouteBase>[
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) => const ProfileCompletionScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard home')),
        ),
      ],
    );
  });

  tearDown(() {
    router.dispose();
    container.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the verified phone and role choices', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text(phone), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('role-shipper')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('role-carrier')), findsOneWidget);
  });

  testWidgets('saves the name and role, then opens the dashboard',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Sushil Thapa');
    await tester.tap(find.byKey(const ValueKey<String>('role-carrier')));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard home'), findsOneWidget);
    final stored = profiles.stored(uid);
    expect(stored?.name, 'Sushil Thapa');
    expect(stored?.role, UserProfile.roleCarrier);
    expect(stored?.isComplete, isTrue);
    expect(profiles.saveCalls, 1);
  });

  testWidgets('blocks Continue without a full name', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    expect(find.text('Dashboard home'), findsNothing);
    expect(profiles.saveCalls, 0);
  });

  testWidgets('offers a retry when the profile API is unreachable',
      (tester) async {
    profiles.failRequests = true;
    await pumpScreen(tester);

    expect(
      find.text('Profile API is unreachable in this test.'),
      findsOneWidget,
    );

    profiles.failRequests = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text(phone), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });
}
