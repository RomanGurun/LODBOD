import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/auth_user.dart';
import '../../features/account/screens/account_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/registration_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/create/screens/create_shipment_screen.dart';
import '../../features/create/screens/order_placed_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/shipments/screens/shipment_detail_screen.dart';
import '../../features/shipments/screens/shipments_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String shipments = '/shipments';
  static const String postLoad = '/post-load';
  static const String orderPlaced = '/order-placed';
  static const String analytics = '/analytics';
  static const String account = '/account';

  static String shipmentDetail(String id) => '$shipments/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh =
      ValueNotifier<AsyncValue<AuthUser?>>(const AsyncLoading<AuthUser?>());

  ref.listen<AsyncValue<AuthUser?>>(authNotifierProvider, (previous, next) {
    refresh.value = next;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onLogin = location == AppRoutes.login;
      final onRegister = location == AppRoutes.register;
      final onOtp = location == AppRoutes.otp;
      final onAuthFlow = onSplash || onLogin || onRegister || onOtp;

      if (auth.isLoading) {
        return onSplash ? null : AppRoutes.splash;
      }

      final user = auth.valueOrNull;
      if (user == null) {
        // Allow access to registration & OTP even when logged out.
        if (onLogin || onRegister || onOtp) return null;
        return AppRoutes.login;
      }

      if (onAuthFlow) return AppRoutes.home;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderPlaced,
        name: 'orderPlaced',
        builder: (context, state) => const OrderPlacedScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.shipments,
                name: 'shipments',
                builder: (context, state) => const ShipmentsScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    name: 'shipmentDetail',
                    builder: (context, state) => ShipmentDetailScreen(
                      shipmentId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.postLoad,
                name: 'postLoad',
                builder: (context, state) => const CreateShipmentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.analytics,
                name: 'analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.account,
                name: 'account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });

  return router;
});
