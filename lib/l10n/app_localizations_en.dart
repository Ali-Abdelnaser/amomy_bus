// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Amomy Bus';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get errorOccurred => 'Something went wrong. Please try again.';

  @override
  String get noData => 'No data available';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to access your trips and tickets';

  @override
  String get email => 'Email Address';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Sign In';

  @override
  String get orDivider => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Join Amomy to travel easily and comfortably';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'e.g. Ahmed Mohamed';

  @override
  String get phone => 'Phone Number';

  @override
  String get phoneHint => '01012345678';

  @override
  String get gender => 'Gender';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get selectDateOfBirth => 'Select Date of Birth';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signInNow => 'Sign In';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String get verifyEmailSubtitle =>
      'We\'ve sent a 6-digit verification code to';

  @override
  String get enterCode => 'Enter the code to verify your account';

  @override
  String get verifyButton => 'Verify Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get changeEmail => 'Change Email / Back';

  @override
  String get completeProfileTitle => 'Complete Your Profile';

  @override
  String get completeProfileSubtitle =>
      'Please provide your details to complete your account setup';

  @override
  String get saveAndContinue => 'Save & Continue';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your registered email address to receive password recovery instructions';

  @override
  String get sendResetInstructions => 'Send Recovery Instructions';

  @override
  String get backToLogin => 'Back to Sign In';

  @override
  String get resetPasswordTitle => 'Set New Password';

  @override
  String get resetPasswordSubtitle =>
      'Choose a strong password with at least 8 characters';

  @override
  String get newPassword => 'New Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdatedSuccess =>
      'Password updated successfully. Please sign in.';

  @override
  String get resetEmailSentSuccess =>
      'Recovery instructions sent. Please check your inbox.';

  @override
  String get homePlaceholderTitle => 'Passenger Home';

  @override
  String get authenticatedAs => 'Signed in as';

  @override
  String get activeRoles => 'Active Roles';

  @override
  String get cashPoints => 'Cash Points';

  @override
  String get subscriptionPoints => 'Subscription Points';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get signOut => 'Sign Out';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmailInvalid => 'Please enter a valid email address';

  @override
  String get validationPhoneInvalid =>
      'Please enter a valid Egyptian phone number (01xxxxxxxxx)';

  @override
  String get validationPasswordLength =>
      'Password must be at least 8 characters';

  @override
  String get validationPasswordComplexity =>
      'Password must contain at least one letter and one number';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationOtpInvalid =>
      'Please enter a valid 6-digit verification code';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get languageSwitchLabel => 'عربي';

  @override
  String get onboardingBookingTitle => 'Book Your Ride Easily';

  @override
  String get onboardingBookingSubtitle =>
      'Choose your trip time and preferred seat in just a few taps.';

  @override
  String get onboardingTrackingTitle => 'Track Your Bus Live';

  @override
  String get onboardingTrackingSubtitle =>
      'Follow your bus location and arrival time in real time.';

  @override
  String get onboardingBoardingTitle => 'Board Quickly & Securely';

  @override
  String get onboardingBoardingSubtitle =>
      'Use your QR code or card for fast and simple boarding.';

  @override
  String get completeProfileReminderTitle => 'Complete your profile';

  @override
  String get completeProfileReminderSubtitle =>
      'Finish your profile to access all AMOMY services.';

  @override
  String get completeNow => 'Complete now';

  @override
  String get bookingGuardTitle => 'Complete your profile first';

  @override
  String get bookingGuardSubtitle =>
      'We need your phone number, gender, and date of birth before booking your trip.';

  @override
  String get completeProfileCta => 'Complete Profile';

  @override
  String get dismiss => 'Dismiss';
}
