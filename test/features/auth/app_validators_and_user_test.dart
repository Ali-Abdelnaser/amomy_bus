import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/validation/app_validators.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_role.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/booking/domain/services/booking_profile_guard.dart';

void main() {
  group('AppValidators', () {
    test('validateFullName requires reasonable name', () {
      expect(AppValidators.validateFullName(null), isNotNull);
      expect(AppValidators.validateFullName(''), isNotNull);
      expect(AppValidators.validateFullName('A'), isNotNull);
      expect(AppValidators.validateFullName('Ali Abdelnaser'), isNull);
    });

    test('validateEmail requires valid email format', () {
      expect(AppValidators.validateEmail(null), isNotNull);
      expect(AppValidators.validateEmail(''), isNotNull);
      expect(AppValidators.validateEmail('invalid-email'), isNotNull);
      expect(AppValidators.validateEmail('test@domain.com'), isNull);
    });

    test('validatePhone requires valid Egyptian phone format initially', () {
      expect(AppValidators.validatePhone(null), isNotNull);
      expect(AppValidators.validatePhone(''), isNotNull);
      expect(AppValidators.validatePhone('12345'), isNotNull);
      expect(AppValidators.validatePhone('01012345678'), isNull);
      expect(AppValidators.validatePhone('01112345678'), isNull);
      expect(AppValidators.validatePhone('01212345678'), isNull);
      expect(AppValidators.validatePhone('01512345678'), isNull);
    });

    test(
      'validatePassword requires at least 8 characters and alphanumeric',
      () {
        expect(AppValidators.validatePassword(null), isNotNull);
        expect(AppValidators.validatePassword('short'), isNotNull);
        expect(AppValidators.validatePassword('onlyletters'), isNotNull);
        expect(AppValidators.validatePassword('12345678'), isNotNull);
        expect(AppValidators.validatePassword('Password123'), isNull);
      },
    );

    test('validateConfirmPassword ensures matching passwords', () {
      expect(
        AppValidators.validateConfirmPassword('pass1', 'pass2'),
        isNotNull,
      );
      expect(AppValidators.validateConfirmPassword('pass1', 'pass1'), isNull);
    });

    test('validateGender requires male or female', () {
      expect(AppValidators.validateGender(null), isNotNull);
      expect(AppValidators.validateGender(''), isNotNull);
      expect(AppValidators.validateGender('other'), isNotNull);
      expect(AppValidators.validateGender('male'), isNull);
      expect(AppValidators.validateGender('female'), isNull);
    });

    test('validateDateOfBirth requires valid past date', () {
      expect(AppValidators.validateDateOfBirth(null), isNotNull);
      expect(
        AppValidators.validateDateOfBirth(
          DateTime.now().add(const Duration(days: 1)),
        ),
        isNotNull,
      );
      expect(AppValidators.validateDateOfBirth(DateTime(2000, 1, 1)), isNull);
    });

    test('validateOtp requires exact 6-digit length', () {
      expect(AppValidators.validateOtp(null), isNotNull);
      expect(AppValidators.validateOtp('123'), isNotNull);
      expect(AppValidators.validateOtp('1234567'), isNotNull);
      expect(AppValidators.validateOtp('abcdef'), isNotNull);
      expect(AppValidators.validateOtp('123456'), isNull);
    });
  });

  group('AppUser Entity and Profile Completion System', () {
    test(
      'isProfileComplete, percentage and missing fields with incomplete user',
      () {
        const incompleteUser = AppUser(
          id: 'u-1',
          email: 'test@example.com',
          fullName: 'Test User',
          roles: [AppRole.passenger],
          isEmailVerified: true,
        );
        // Only full_name and email are provided (2 of 5)
        expect(incompleteUser.isProfileComplete, isFalse);
        expect(
          incompleteUser.missingProfileFields,
          equals(['phone', 'gender', 'date_of_birth']),
        );
        expect(
          incompleteUser.profileCompletionPercentage,
          equals(2 / 5),
        ); // 0.4
        expect(incompleteUser.profileCompletionPercent, equals(40));
        expect(BookingProfileGuard.canBook(incompleteUser), isFalse);
      },
    );

    test(
      'isProfileComplete, percentage and booking guard with complete user',
      () {
        const incompleteUser = AppUser(
          id: 'u-1',
          email: 'test@example.com',
          fullName: 'Test User',
          roles: [AppRole.passenger],
          isEmailVerified: true,
        );

        final completeUser = incompleteUser.copyWith(
          phone: '01012345678',
          gender: 'male',
          dateOfBirth: DateTime(1995, 5, 20),
        );
        expect(completeUser.isProfileComplete, isTrue);
        expect(completeUser.missingProfileFields, isEmpty);
        expect(completeUser.profileCompletionPercentage, equals(1.0));
        expect(completeUser.profileCompletionPercent, equals(100));
        expect(BookingProfileGuard.canBook(completeUser), isTrue);
      },
    );

    test(
      'avatar is optional and does not affect isProfileComplete or percentage',
      () {
        final userWithoutAvatar = const AppUser(
          id: 'u-1',
          email: 'test@example.com',
          fullName: 'Test User',
          phone: '01012345678',
          gender: 'female',
          dateOfBirth: null,
        );
        // 4 out of 5 fields (missing date_of_birth)
        expect(
          userWithoutAvatar.profileCompletionPercentage,
          equals(4 / 5),
        ); // 0.8
        expect(userWithoutAvatar.isProfileComplete, isFalse);

        final userWithAvatar = userWithoutAvatar.copyWith(
          avatarUrl: 'https://lh3.googleusercontent.com/a/photo.jpg',
        );
        // Adding avatar does NOT count towards the 5 required fields
        expect(userWithAvatar.profileCompletionPercentage, equals(4 / 5));
        expect(userWithAvatar.isProfileComplete, isFalse);

        final fullyComplete = userWithAvatar.copyWith(
          dateOfBirth: DateTime(1998, 2, 14),
        );
        expect(fullyComplete.isProfileComplete, isTrue);
        expect(fullyComplete.profileCompletionPercentage, equals(1.0));
        expect(BookingProfileGuard.canBook(fullyComplete), isTrue);
      },
    );

    test('AppRole helpers and permissions', () {
      expect(AppRole.fromString('passenger'), equals(AppRole.passenger));
      expect(AppRole.fromString('staff'), equals(AppRole.staff));
      expect(AppRole.fromString('admin'), equals(AppRole.admin));
      expect(AppRole.fromString('super_admin'), equals(AppRole.superAdmin));
      expect(AppRole.fromString('unknown'), equals(AppRole.passenger));

      expect(AppRole.passenger.isAdmin, isFalse);
      expect(AppRole.admin.isAdmin, isTrue);
      expect(AppRole.superAdmin.isAdmin, isTrue);
      expect(AppRole.staff.isStaff, isTrue);
    });
  });
}
