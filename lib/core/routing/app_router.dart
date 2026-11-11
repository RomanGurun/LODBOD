import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/account/presentation/screens/account_screen.dart';
import 'package:lodbod/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/features/auth/presentation/screens/login_screen.dart';
import 'package:lodbod/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:lodbod/features/auth/presentation/screens/profile_completion_screen.dart';
import 'package:lodbod/features/auth/presentation/screens/registration_screen.dart';
import 'package:lodbod/features/auth/presentation/screens/splash_screen.dart';
import 'package:lodbod/features/create_shipment/presentation/screens/create_shipment_screen.dart';
import 'package:lodbod/features/create_shipment/presentation/screens/order_placed_screen.dart';
import 'package:lodbod/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:lodbod/core/widgets/main_shell.dart';
import 'package:lodbod/features/shipments/presentation/screens/shipment_detail_screen.dart';
import 'package:lodbod/features/shipments/presentation/screens/shipments_screen.dart';
import 'package:lodbod/features/shipments/presentation/screens/tracking_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String completeProfile = '/complete-profile';
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
  final profileRefresh = ValueNotifier<AsyncValue<UserProfile?>>(
      const AsyncLoading<UserProfile?>());

  // Keeps the branded splash on screen for a moment on cold start instead of
  // flashing for a single frame. It only gates the initial session check —
  // sign-in/sign-up actions keep their own screen (and inline spinner).
  final splashGate = ValueNotifier<bool>(true);
  final splashTimer = Timer(AppDurations.splash, () {
    splashGate.value = false;
  });

  ref.listen<AsyncValue<AuthUser?>>(authNotifierProvider, (previous, next) {
    refresh.value = next;
  });

  ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) {
    profileRefresh.value = next;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable:
        Listenable.merge(<Listenable>[refresh, profileRefresh, splashGate]),
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onLogin = location == AppRoutes.login;
      final onRegister = location == AppRoutes.register;
      final onOtp = location == AppRoutes.otp;
      final onCompleteProfile = location == AppRoutes.completeProfile;
      final onAuthFlow = onSplash || onLogin || onRegister || onOtp;

      if (splashGate.value) {
        return onSplash ? null : AppRoutes.splash;
      }

      if (auth.isLoading) {
        // Initial session restore on the splash, or an auth action on
        // login/register/otp: stay put so the in-screen spinner is visible
        // instead of bouncing through the splash screen.
        return null;
      }

      final user = auth.valueOrNull;
      if (user == null) {
        // Allow the registration and OTP screens while logged out.
        if (onLogin || onRegister || onOtp) return null;
        return AppRoutes.login;
      }

      final profile = ref.read(userProfileProvider);
      if (profile.isLoading) {
        // Phone sign-in has succeeded; the profile is still being resolved.
        // Keep the current screen's spinner visible (the OTP screen shows one).
        return null;
      }

      if (profile.hasError) {
        // The Firebase session is valid but the MockAPI profile could not be
        // read or created. The completion screen exposes a retry.
        return onCompleteProfile ? null : AppRoutes.completeProfile;
      }

      final profileComplete = profile.valueOrNull?.isComplete ?? false;
      if (!profileComplete) {
        return onCompleteProfile ? null : AppRoutes.completeProfile;
      }

      // The confirmation page only makes sense straight after submission.
      if (location == AppRoutes.orderPlaced && state.extra is! Shipment) {
        return AppRoutes.shipments;
      }

      if (onAuthFlow || onCompleteProfile) return AppRoutes.home;
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
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        name: 'completeProfile',
        builder: (context, state) => const ProfileCompletionScreen(),
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
    splashTimer.cancel();
    router.dispose();
    refresh.dispose();
    profileRefresh.dispose();
    splashGate.dispose();
  });

  return router;
});
