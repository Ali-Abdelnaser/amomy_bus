import 'dart:async';
import 'package:flutter/foundation.dart';
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
import '../../features/auth/presentation/pages/passenger_home_placeholder_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/debug/presentation/pages/design_system_preview_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'route_names.dart';
import 'route_paths.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

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
          child: EmailVerificationPage(
            email: state.extra as String?,
          ),
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

      // Home (Placeholder for Session Proof)
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        pageBuilder: (context, state) => AppPageTransitions.standardPage(
          key: state.pageKey,
          name: state.name,
          child: const PassengerHomePlaceholderPage(),
        ),
      ),

      // Debug: Design System Gallery
      if (kDebugMode)
        GoRoute(
          path: RoutePaths.designSystemPreview,
          name: RouteNames.designSystemPreview,
          pageBuilder: (context, state) => AppPageTransitions.standardPage(
            key: state.pageKey,
            name: state.name,
            child: const DesignSystemPreviewPage(),
          ),
        ),
    ],
    redirect: (context, state) {
      final authState = _authBloc.state;
      final location = state.matchedLocation;

      final isSplash = location == RoutePaths.splash;
      final isOnboarding = location == RoutePaths.onboarding;
      final isDesignSystem = location == RoutePaths.designSystemPreview;
      final isAuthRoute = location == RoutePaths.login ||
          location == RoutePaths.register ||
          location == RoutePaths.forgotPassword ||
          location == RoutePaths.resetPassword;
      final isVerifyEmail = location == RoutePaths.emailVerification;

      // Always permit design system preview in debug
      if (isDesignSystem) return null;

      // Allow onboarding and splash on initial launch / unauthenticated
      if (authState is AuthInitial) {
        return null;
      }

      // If user is unauthenticated or has auth failure
      if (authState is Unauthenticated || authState is AuthFailureState) {
        if (isOnboarding || isAuthRoute) return null;
        return RoutePaths.login;
      }

      // If email verification is pending
      if (authState is EmailVerificationRequired) {
        if (isVerifyEmail) return null;
        return RoutePaths.emailVerification;
      }

      // If user is authenticated (incomplete profile does NOT block Home)
      if (authState is Authenticated) {
        if (isSplash || isAuthRoute || isVerifyEmail) {
          return RoutePaths.home;
        }
        // Permitted routes: /home, /complete-profile, etc.
        return null;
      }

      return null;
    },
  );
}
