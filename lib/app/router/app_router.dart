import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import '../../core/animations/app_page_transitions.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/booking/domain/entities/booking_entities.dart';
import '../../features/booking/presentation/pages/book_trip_page.dart';
import '../../features/home/presentation/pages/passenger_home_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/about_app_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/support_center_page.dart';
import '../../features/profile/presentation/pages/terms_and_conditions_page.dart';
import '../../features/shell/presentation/pages/passenger_shell_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/topup/domain/entities/topup_entities.dart';
import '../../features/topup/presentation/pages/add_points_page.dart';
import '../../features/trips/presentation/cubit/passenger_trips_cubit.dart';
import '../../features/trips/presentation/pages/change_seat_page.dart';
import '../../features/trips/presentation/pages/my_trips_page.dart';
import '../../features/trips/presentation/pages/trip_history_page.dart';
import '../../features/tracking/presentation/screens/live_map_screen.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import 'route_names.dart';
import 'route_paths.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

/// Converts Stream to Listenable for GoRouter refresh
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

@lazySingleton
class AppRouter {
  final AuthBloc _authBloc;

  AppRouter(this._authBloc);

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        pageBuilder: (context, state) => AppPageTransitions.fadePage(
          key: state.pageKey,
          name: state.name,
          child: const SplashPage(),
        ),
      ),

      // Onboarding
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        pageBuilder: (context, state) => AppPageTransitions.fadePage(
          key: state.pageKey,
          name: state.name,
          child: const OnboardingPage(),
        ),
      ),

      // Auth: Login
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const LoginPage(),
        ),
      ),

      // Auth: Register
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const RegisterPage(),
        ),
      ),

      // Auth: Email Verification (OTP)
      GoRoute(
        path: RoutePaths.emailVerification,
        name: RouteNames.emailVerification,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: EmailVerificationPage(email: state.extra as String?),
        ),
      ),

      // Auth: Complete Profile
      GoRoute(
        path: RoutePaths.completeProfile,
        name: RouteNames.completeProfile,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const CompleteProfilePage(),
        ),
      ),

      // Auth: Forgot Password
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const ForgotPasswordPage(),
        ),
      ),

      // Auth: Reset Password
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const ResetPasswordPage(),
        ),
      ),

      // Passenger Navigation Shell (Persistent tabs: Home, Trips, Wallet, Profile)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return PassengerShellPage(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                pageBuilder: (context, state) => AppPageTransitions.fadePage(
                  key: state.pageKey,
                  name: state.name,
                  child: const PassengerHomePage(),
                ),
              ),
            ],
          ),

          // Branch 1: My Trips
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.trips,
                name: RouteNames.trips,
                pageBuilder: (context, state) => AppPageTransitions.fadePage(
                  key: state.pageKey,
                  name: state.name,
                  child: const MyTripsPage(),
                ),
              ),
            ],
          ),

          // Branch 2: Wallet
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.wallet,
                name: RouteNames.wallet,
                pageBuilder: (context, state) => AppPageTransitions.fadePage(
                  key: state.pageKey,
                  name: state.name,
                  child: const WalletPage(),
                ),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                pageBuilder: (context, state) => AppPageTransitions.fadePage(
                  key: state.pageKey,
                  name: state.name,
                  child: const ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Booking entry route
      GoRoute(
        path: RoutePaths.bookTrip,
        name: RouteNames.bookTrip,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AppPageTransitions.standardPage(
            key: state.pageKey,
            name: state.name,
            child: BookTripPage(
              initialTripId: extra?['trip_id'] as String?,
              initialDirection: extra?['direction'] as BookingDirection?,
              initialOriginStopId: extra?['origin_stop_id'] as String?,
              initialDestinationStopId:
                  extra?['destination_stop_id'] as String?,
            ),
          );
        },
      ),

      // Add Points route
      GoRoute(
        path: RoutePaths.addPoints,
        name: RouteNames.addPoints,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final resubmitRequest = extra is TopUpRequest ? extra : null;
          final points = extra is int
              ? extra
              : (extra is num ? extra.toInt() : 0);
          return AppPageTransitions.standardPage(
            key: state.pageKey,
            name: state.name,
            child: AddPointsPage(
              initialAvailablePoints: points,
              resubmitRequest: resubmitRequest,
            ),
          );
        },
      ),

      // Trip History route
      GoRoute(
        path: RoutePaths.myBookings,
        name: RouteNames.myBookings,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const TripHistoryPage(),
        ),
      ),

      // Change Seat route (Full-page seat map)
      GoRoute(
        path: RoutePaths.changeSeat,
        name: RouteNames.changeSeat,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AppPageTransitions.standardPage(
            key: state.pageKey,
            name: state.name,
            child: ChangeSeatPage(
              trip: extra!['trip'] as PassengerTodayTrip,
              tripsCubit: extra['tripsCubit'] as PassengerTripsCubit,
            ),
          );
        },
      ),

      // Dedicated Live Bus Map screen (Available to ALL passengers)
      GoRoute(
        path: RoutePaths.liveBusMap,
        name: RouteNames.liveBusMap,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const LiveMapScreen(),
        ),
      ),

      // Notifications Inbox
      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const NotificationsPage(),
        ),
      ),

      // Notification Settings
      GoRoute(
        path: RoutePaths.notificationSettings,
        name: RouteNames.notificationSettings,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const NotificationSettingsPage(),
        ),
      ),

      // Profile: Personal Information (Edit Mode)
      GoRoute(
        path: RoutePaths.personalInformation,
        name: RouteNames.personalInformation,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const CompleteProfilePage(),
        ),
      ),

      // Profile: Support Center
      GoRoute(
        path: RoutePaths.support,
        name: RouteNames.support,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const SupportCenterPage(),
        ),
      ),

      // Profile: About AMOMY App
      GoRoute(
        path: RoutePaths.aboutApp,
        name: RouteNames.aboutApp,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const AboutAppPage(),
        ),
      ),

      // Profile: Privacy Policy
      GoRoute(
        path: RoutePaths.privacyPolicy,
        name: RouteNames.privacyPolicy,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const PrivacyPolicyPage(),
        ),
      ),

      // Profile: Terms & Conditions
      GoRoute(
        path: RoutePaths.termsAndConditions,
        name: RouteNames.termsAndConditions,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const TermsAndConditionsPage(),
        ),
      ),

      // Legacy/deep-link trip-linked live tracking path
      GoRoute(
        path: RoutePaths.liveTracking,
        name: RouteNames.liveTracking,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const LiveMapScreen(),
        ),
      ),

      // Debug: Design System Gallery (ONLY in debug mode)
    ],
    redirect: (context, state) =>
        redirectLogic(_authBloc.state, state.matchedLocation),
  );

  static String? redirectLogic(AuthState authState, String location) {
    final isSplash = location == RoutePaths.splash;
    final isOnboarding = location == RoutePaths.onboarding;
    final isDesignSystem = location == RoutePaths.designSystemPreview;
    final isAuthRoute =
        location == RoutePaths.login ||
        location == RoutePaths.register ||
        location == RoutePaths.forgotPassword ||
        location == RoutePaths.resetPassword ||
        location == RoutePaths.emailVerification;

    // Always permit design system preview in debug
    if (isDesignSystem) return null;

    // Allow onboarding and splash on initial launch / unauthenticated
    if (authState is AuthInitial) {
      return null;
    }

    // If user is explicitly unauthenticated
    if (authState is Unauthenticated) {
      if (isOnboarding || isAuthRoute) return null;
      return RoutePaths.login;
    }

    // If an auth operation failed: never redirect to login from completeProfile
    if (authState is AuthFailureState) {
      if (isOnboarding ||
          isAuthRoute ||
          location == RoutePaths.completeProfile) {
        return null;
      }
      return RoutePaths.login;
    }

    // If email verification is pending
    if (authState is EmailVerificationRequired) {
      if (isAuthRoute) return null;
      return RoutePaths.emailVerification;
    }

    // If profile completion is explicitly pending
    if (authState is ProfileCompletionRequired) {
      if (location == RoutePaths.completeProfile) return null;
      return RoutePaths.completeProfile;
    }

    // If user is authenticated: enforce strict profile completion guard
    if (authState is Authenticated) {
      final isComplete = authState.user.isProfileComplete;
      if (!isComplete) {
        if (location == RoutePaths.completeProfile) return null;
        return RoutePaths.completeProfile;
      }

      if (isSplash || isAuthRoute) {
        return RoutePaths.home;
      }
      // Permitted routes when complete: /home, /complete-profile (edit mode), etc.
      return null;
    }

    return null;
  }
}
