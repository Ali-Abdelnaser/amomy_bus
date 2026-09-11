/// Centralized validation logic for Amomy Bus.
///
/// Contains form validators for registration, login, OTP, and profile completion.
/// Methods return `null` if valid, or a non-localized key / error description.
/// To support localization, methods accept an optional localized error string callback
/// or return standard error messages that can be localized.
class AppValidators {
  const AppValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Matches Egyptian mobile numbers:
  /// - Starts with 010, 011, 012, or 015 followed by 8 digits (11 digits total)
  /// - Or international prefix +2010, +2011, +2012, +2015 followed by 8 digits
  static final RegExp _egyptianPhoneRegex = RegExp(
    r'^(?:\+20|0020|0)?1[0125][0-9]{8}$',
  );

  static final RegExp _hasLetterRegex = RegExp(r'[a-zA-Z]');
  static final RegExp _hasDigitRegex = RegExp(r'[0-9]');

  /// Validates Full Name
  static String? validateFullName(String? value, {String? requiredMessage, String? minLengthMessage}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredMessage ?? 'Full name is required';
    }
    if (trimmed.length < 3) {
      return minLengthMessage ?? 'Name must be at least 3 characters';
    }
    return null;
  }

  /// Validates Email address
  static String? validateEmail(String? value, {String? requiredMessage, String? invalidMessage}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredMessage ?? 'Email address is required';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return invalidMessage ?? 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates Phone number (Egyptian format initially, extensible)
  static String? validatePhone(String? value, {String? requiredMessage, String? invalidMessage}) {
    final trimmed = value?.trim().replaceAll(RegExp(r'[\s\-]'), '') ?? '';
    if (trimmed.isEmpty) {
      return requiredMessage ?? 'Phone number is required';
    }
    if (!_egyptianPhoneRegex.hasMatch(trimmed)) {
      return invalidMessage ?? 'Please enter a valid Egyptian phone number (e.g. 01012345678)';
    }
    return null;
  }

  /// Normalizes phone number to standard Egyptian 11-digit format (01xxxxxxxxx)
  static String normalizeEgyptianPhone(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+20')) {
      return '0${cleaned.substring(3)}';
    }
    if (cleaned.startsWith('0020')) {
      return '0${cleaned.substring(4)}';
    }
    if (!cleaned.startsWith('0') && cleaned.length == 10 && cleaned.startsWith('1')) {
      return '0$cleaned';
    }
    return cleaned;
  }

  /// Validates Password (min 8 characters, at least 1 letter and 1 digit)
  static String? validatePassword(
    String? value, {
    String? requiredMessage,
    String? minLengthMessage,
    String? complexityMessage,
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage ?? 'Password is required';
    }
    if (value.length < 8) {
      return minLengthMessage ?? 'Password must be at least 8 characters';
    }
    if (!_hasLetterRegex.hasMatch(value) || !_hasDigitRegex.hasMatch(value)) {
      return complexityMessage ?? 'Password must contain at least one letter and one number';
    }
    return null;
  }

  /// Validates Confirm Password
  static String? validateConfirmPassword(
    String? value,
    String? originalPassword, {
    String? requiredMessage,
    String? mismatchMessage,
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage ?? 'Please confirm your password';
    }
    if (value != originalPassword) {
      return mismatchMessage ?? 'Passwords do not match';
    }
    return null;
  }

  /// Validates Gender selection ('male' or 'female')
  static String? validateGender(String? value, {String? requiredMessage}) {
    if (value == null || value.trim().isEmpty) {
      return requiredMessage ?? 'Please select your gender';
    }
    final lower = value.trim().toLowerCase();
    if (lower != 'male' && lower != 'female') {
      return requiredMessage ?? 'Gender must be either male or female';
    }
    return null;
  }

  /// Validates Date of Birth
  static String? validateDateOfBirth(
    DateTime? value, {
    String? requiredMessage,
    String? futureDateMessage,
    String? unreasonableMessage,
  }) {
    if (value == null) {
      return requiredMessage ?? 'Date of birth is required';
    }
    final now = DateTime.now();
    if (value.isAfter(now)) {
      return futureDateMessage ?? 'Date of birth cannot be in the future';
    }
    // Prevent unrealistic dates
    if (value.year < 1900) {
      return unreasonableMessage ?? 'Please enter a valid date of birth';
    }
    return null;
  }

  /// Validates 6-digit OTP code
  static String? validateOtp(String? value, {int length = 6, String? requiredMessage, String? invalidMessage}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredMessage ?? 'Verification code is required';
    }
    if (trimmed.length != length || int.tryParse(trimmed) == null) {
      return invalidMessage ?? 'Verification code must be exactly $length digits';
    }
    return null;
  }
}
