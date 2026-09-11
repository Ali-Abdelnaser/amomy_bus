import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/validation/app_validators.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_role.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';

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
      expect(AppValidators.validateEmail('user@domain'), isNotNull);
      expect(AppValidators.validateEmail('user@example.com'), isNull);
      expect(AppValidators.validateEmail('passenger@amomy.com'), isNull);
    });

    test('validatePhone requires valid Egyptian phone format initially', () {
      expect(AppValidators.validatePhone(null), isNotNull);
      expect(AppValidators.validatePhone(''), isNotNull);
      expect(AppValidators.validatePhone('123456789'), isNotNull);
      expect(AppValidators.validatePhone('0212345678'), isNotNull);
      // Egyptian mobile starts with 010, 011, 012, 015
      expect(AppValidators.validatePhone('01012345678'), isNull);
      expect(AppValidators.validatePhone('01112345678'), isNull);
      expect(AppValidators.validatePhone('01212345678'), isNull);
      expect(AppValidators.validatePhone('01512345678'), isNull);
      expect(AppValidators.validatePhone('+201012345678'), isNull);
    });

    test('validatePassword requires at least 8 characters and alphanumeric', () {
      expect(AppValidators.validatePassword(null), isNotNull);
      expect(AppValidators.validatePassword('short'), isNotNull);
      expect(AppValidators.validatePassword('allletterspassword'), isNotNull);
      expect(AppValidators.validatePassword('12345678'), isNotNull);
      expect(AppValidators.validatePassword('ValidPass123'), isNull);
    });

    test('validateConfirmPassword ensures matching passwords', () {
      expect(AppValidators.validateConfirmPassword(null, 'ValidPass123'), isNotNull);
      expect(AppValidators.validateConfirmPassword('Different123', 'ValidPass123'), isNotNull);
      expect(AppValidators.validateConfirmPassword('ValidPass123', 'ValidPass123'), isNull);
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
      expect(AppValidators.validateDateOfBirth(DateTime.now().add(const Duration(days: 1))), isNotNull);
      expect(AppValidators.validateDateOfBirth(DateTime(1995, 5, 20)), isNull);
    });

    test('validateOtp requires exact 6-digit length', () {
      expect(AppValidators.validateOtp(null), isNotNull);
      expect(AppValidators.validateOtp('12345'), isNotNull);
      expect(AppValidators.validateOtp('1234567'), isNotNull);
      expect(AppValidators.validateOtp('12345a'), isNotNull);
      expect(AppValidators.validateOtp('123456'), isNull);
    });
  });

  group('AppUser Entity', () {
    test('isProfileComplete decision', () {
      const incompleteUser = AppUser(
        id: 'u-1',
        email: 'test@example.com',
        fullName: 'Test User',
        roles: [AppRole.passenger],
        isEmailVerified: true,
      );
      expect(incompleteUser.isProfileComplete, isFalse);

      final completeUser = incompleteUser.copyWith(
        phone: '01012345678',
        gender: 'male',
        dateOfBirth: DateTime(1995, 5, 20),
      );
      expect(completeUser.isProfileComplete, isTrue);
    });

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
