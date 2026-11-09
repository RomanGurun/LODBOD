import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String shipments = '/shipments';
  static const String postLoad = '/post-load';
  static const String analytics = '/analytics';
  static const String account = '/account';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
  ],
);
