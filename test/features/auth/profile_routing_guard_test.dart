import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/app/router/app_router.dart';
import 'package:amomy_bus/app/router/route_paths.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_role.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';

void main() {
  const incompleteUser = AppUser(
    id: 'user-incomplete',
    email: 'incomplete@amomy.com',
    fullName: 'Incomplete User',
    phone: null,
    gender: null,
    dateOfBirth: null,
    roles: [AppRole.passenger],
    isEmailVerified: true,
  );

  final completeUser = AppUser(
    id: 'user-complete',
    email: 'complete@amomy.com',
    fullName: 'Complete User',
    phone: '01012345678',
    gender: 'male',
    dateOfBirth: DateTime(1995, 1, 1),
    roles: const [AppRole.passenger],
    isEmailVerified: true,
  );

  group('AppRouter Strict Profile Completion Guards', () {
    test('Unauthenticated user attempting /home redirects to /login', () {
      final redirect = AppRouter.redirectLogic(
        const Unauthenticated(),
        RoutePaths.home,
      );
      expect(redirect, equals(RoutePaths.login));
    });

    test('Incomplete authenticated user attempting /home redirects to /complete-profile', () {
      final redirect = AppRouter.redirectLogic(
        const Authenticated(user: incompleteUser),
        RoutePaths.home,
      );
      expect(redirect, equals(RoutePaths.completeProfile));
    });

    test('Incomplete authenticated user attempting /wallet redirects to /complete-profile', () {
      final redirect = AppRouter.redirectLogic(
        const Authenticated(user: incompleteUser),
        RoutePaths.wallet,
      );
      expect(redirect, equals(RoutePaths.completeProfile));
    });

    test('Incomplete authenticated user attempting booking redirects to /complete-profile', () {
      final redirect = AppRouter.redirectLogic(
        const Authenticated(user: incompleteUser),
        RoutePaths.bookTrip,
      );
      expect(redirect, equals(RoutePaths.completeProfile));
    });

    test('Incomplete authenticated user attempting /trips redirects to /complete-profile', () {
      final redirect = AppRouter.redirectLogic(
        const Authenticated(user: incompleteUser),
        RoutePaths.trips,
      );
      expect(redirect, equals(RoutePaths.completeProfile));
    });

    test('Incomplete authenticated user attempting /profile redirects to /complete-profile', () {
      final redirect = AppRouter.redirectLogic(
        const Authenticated(user: incompleteUser),
        RoutePaths.profile,
      );
      expect(redirect, equals(RoutePaths.completeProfile));
    });

    test('Incomplete user on /complete-profile is allowed (no redirect loop)', () {
      final redirect = AppRouter.redirectLogic(
        const Authenticated(user: incompleteUser),
        RoutePaths.completeProfile,
      );
      expect(redirect, isNull);
    });

    test('Complete user attempting /home is allowed (no redirect)', () {
      final redirect = AppRouter.redirectLogic(
        Authenticated(user: completeUser),
        RoutePaths.home,
      );
      expect(redirect, isNull);
    });

    test('Complete user on /complete-profile in edit mode is allowed (no redirect)', () {
      final redirect = AppRouter.redirectLogic(
        Authenticated(user: completeUser),
        RoutePaths.completeProfile,
      );
      expect(redirect, isNull);
    });

    test('Complete user with ProfileSaveFailure on /complete-profile in edit mode does NOT redirect to /login', () {
      final redirect = AppRouter.redirectLogic(
        ProfileSaveFailure(
          user: completeUser,
          failure: const ServerFailure(message: 'Database error'),
        ),
        RoutePaths.completeProfile,
      );
      expect(redirect, isNull);
    });

    test('Incomplete user with ProfileSaveFailure on /complete-profile remains on /complete-profile (no /login redirect)', () {
      final redirect = AppRouter.redirectLogic(
        const ProfileSaveFailure(
          user: incompleteUser,
          failure: ServerFailure(message: 'Database error'),
        ),
        RoutePaths.completeProfile,
      );
      expect(redirect, isNull);
    });

    test('Complete user with ProfileSaving on /complete-profile is allowed (no redirect)', () {
      final redirect = AppRouter.redirectLogic(
        ProfileSaving(user: completeUser),
        RoutePaths.completeProfile,
      );
      expect(redirect, isNull);
    });

    test('AuthFailureState while on /complete-profile does NOT redirect to /login', () {
      final redirect = AppRouter.redirectLogic(
        const AuthFailureState(ServerFailure(message: 'Temporary failure')),
        RoutePaths.completeProfile,
      );
      expect(redirect, isNull);
    });
  });
}
