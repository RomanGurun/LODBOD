import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/domain/entities/auth_user.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'package:lodbod/features/account/screens/account_screen.dart';
import 'package:lodbod/features/analytics/screens/analytics_screen.dart';
import 'package:lodbod/features/auth/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/screens/login_screen.dart';
import 'package:lodbod/features/auth/screens/otp_screen.dart';
import 'package:lodbod/features/auth/screens/registration_screen.dart';
import 'package:lodbod/features/auth/screens/splash_screen.dart';
import 'package:lodbod/features/create/screens/create_shipment_screen.dart';
import 'package:lodbod/features/create/screens/order_placed_screen.dart';
import 'package:lodbod/features/dashboard/screens/dashboard_screen.dart';
import 'package:lodbod/features/home/screens/main_shell.dart';
import 'package:lodbod/features/shipments/screens/shipment_detail_screen.dart';
import 'package:lodbod/features/shipments/screens/shipments_screen.dart';
import 'package:lodbod/features/tracking/screens/tracking_screen.dart';

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
  static String shipmentTracking(String id) => '$shipments/$id/tracking';

  /// Deep-link into the shipments list with a pre-applied filter.
  ///
  /// `active` opens only active shipments; a status wire value (e.g.
  /// `awaiting_bids`) opens the list filtered by that status.
  static String shipmentsFiltered(String filter) => '$shipments?filter=$filter';
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

      // The confirmation page only makes sense straight after submission.
      if (location == AppRoutes.orderPlaced && state.extra is! Shipment) {
        return AppRoutes.shipments;
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
        builder: (context, state) {
          final shipment = state.extra;
          return shipment is Shipment
              ? OrderPlacedScreen.fromShipment(shipment)
              : const OrderPlacedScreen();
        },
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
                builder: (context, state) {
                  final filter = state.uri.queryParameters['filter'];
                  return ShipmentsScreen(
                    key: ValueKey<String>('shipments-$filter'),
                    initialFilter: filter,
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    name: 'shipmentDetail',
                    builder: (context, state) => ShipmentDetailScreen(
                      shipmentId: state.pathParameters['id'] ?? '',
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'tracking',
                        name: 'tracking',
                        builder: (context, state) => TrackingScreen(
                          shipmentId: state.pathParameters['id'] ?? '',
                        ),
                      ),
                    ],
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
