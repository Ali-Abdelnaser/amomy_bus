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

  @override
  String get navHome => 'Home';

  @override
  String get navMyTrips => 'My Trips';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get pointsBalance => 'Points Balance';

  @override
  String get pointsUnit => 'Points';

  @override
  String get addPoints => 'Add Points';

  @override
  String get walletDetails => 'Details';

  @override
  String get cashPointsPrefix => 'Cash points';

  @override
  String get subscriptionPointsPrefix => 'Subscription points';

  @override
  String get bookRideTitle => 'Book Your Ride';

  @override
  String get bookRideSubtitle =>
      'Choose your departure time and preferred seat.';

  @override
  String get bookNow => 'Book Now';

  @override
  String get upcomingTrip => 'Upcoming Trip';

  @override
  String get noUpcomingTrip => 'No upcoming trip';

  @override
  String get bookTripCta => 'Book a Ride';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get actionAddPoints => 'Add Points';

  @override
  String get actionMyTrips => 'My Trips';

  @override
  String get actionSubscriptions => 'Subscriptions';

  @override
  String get actionSupport => 'Support';

  @override
  String get support => 'Support';

  @override
  String get upcomingTab => 'Upcoming';

  @override
  String get historyTab => 'History';

  @override
  String get noTripsFound => 'No trips yet';

  @override
  String get noTripsSubtitle =>
      'When you book a trip, it will appear right here.';

  @override
  String get transactions => 'Transactions';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsSubtitle =>
      'Your points recharge and trip payments will show here.';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get language => 'Language';

  @override
  String get aboutAmomy => 'About AMOMY';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmMessage =>
      'Are you sure you want to sign out from AMOMY?';

  @override
  String get cancel => 'Cancel';

  @override
  String get featureUnderDevelopment => 'Feature Under Development';

  @override
  String get bookingComingSoonDesc =>
      'Trip booking and seat selection is currently under development.';

  @override
  String get subscriptionsComingSoonDesc =>
      'Subscription plans will be available soon.';

  @override
  String get supportDialogTitle => 'AMOMY Customer Support';

  @override
  String get supportDialogDesc =>
      'Our support team is available 24/7 to assist you with your trips and account.';

  @override
  String get quickBooking => 'Fast & Direct';

  @override
  String get directionOutbound => 'Outbound';

  @override
  String get directionReturn => 'Return';

  @override
  String get selectDirection => 'Select Direction';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get selectSeat => 'Select Seat';

  @override
  String get reviewBooking => 'Review Booking';

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String seatsAvailableCount(int count) {
    return '$count seats available';
  }

  @override
  String get seatStatusAvailable => 'Available';

  @override
  String get seatStatusHeld => 'Held';

  @override
  String get seatStatusBooked => 'Booked';

  @override
  String get seatStatusSelected => 'Selected';

  @override
  String get driverFront => 'Front / Driver';

  @override
  String holdCountdown(String time) {
    return 'Seat hold expires in $time';
  }

  @override
  String get holdExpiredNotice =>
      'Your seat hold has expired. Please select a seat again.';

  @override
  String get seatUnavailableNotice =>
      'This seat is no longer available. Please select another seat.';

  @override
  String get insufficientPointsNotice =>
      'Insufficient points balance. Please recharge your points to continue.';

  @override
  String get bookingSuccessTitle => 'Booking Confirmed!';

  @override
  String get bookingSuccessSubtitle =>
      'Your trip seat is successfully reserved.';

  @override
  String get qrTicketInstruction =>
      'Present this QR code to the driver or scanner upon boarding.';

  @override
  String get viewMyTrips => 'View My Trips';

  @override
  String get tripDetailsDirection => 'Direction';

  @override
  String get tripDetailsDate => 'Date';

  @override
  String get tripDetailsTime => 'Departure Time';

  @override
  String get tripDetailsSeat => 'Seat Number';

  @override
  String get tripDetailsFare => 'Trip Fare';

  @override
  String get tripDetailsRoute => 'Route';

  @override
  String get tripStatusScheduled => 'Scheduled';

  @override
  String get tripStatusBoarding => 'Boarding';

  @override
  String get tripStatusDeparted => 'Departed';

  @override
  String get tripStatusCompleted => 'Completed';

  @override
  String get tripStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get pointsBalanceAvailable => 'Available Points';

  @override
  String get completeProfileToBook =>
      'Please complete your profile to book trips.';

  @override
  String get topUpAmountTitle => 'Amount';

  @override
  String get topUpAmountHint => 'Enter amount in EGP';

  @override
  String get topUpPointsRatio => '1 EGP ≈ 1 Point';

  @override
  String get topUpSelectMethod => 'Select Payment Method';

  @override
  String get topUpInstructions => 'Transfer Instructions';

  @override
  String get topUpRecipientAccount => 'Recipient Account / Number';

  @override
  String get topUpCopyAccount => 'Copy Number';

  @override
  String get topUpCopiedToast => 'Account number copied to clipboard';

  @override
  String get topUpTransactionReference => 'Transaction Reference';

  @override
  String get topUpTransactionReferenceHint =>
      'Enter transaction or transfer reference';

  @override
  String get topUpTransactionReferenceHelper =>
      'Enter the transfer reference to help us verify your payment quickly.';

  @override
  String get topUpPaymentProof => 'Payment Proof Screenshot';

  @override
  String get topUpUploadScreenshot => 'Upload Screenshot';

  @override
  String get topUpChangeScreenshot => 'Change Screenshot';

  @override
  String get topUpReviewTitle => 'Review Top-Up Request';

  @override
  String get topUpExpectedPoints => 'Expected Cash Points';

  @override
  String get topUpSubmitButton => 'Submit Top-Up Request';

  @override
  String get topUpSubmitting => 'Submitting...';

  @override
  String get topUpPendingSuccessTitle => 'Top-up request submitted';

  @override
  String get topUpPendingSuccessDesc =>
      'Your request is under review.\nPoints will be added to your wallet after approval.';

  @override
  String get topUpBackToWallet => 'Return to Wallet';

  @override
  String get topUpManualNotice =>
      'Manual review: This is not an instant gateway. Our team verifies transfers before crediting points.';

  @override
  String get topUpHistoryTitle => 'Top-Up Requests';

  @override
  String get topUpStatusPending => 'Under Review';

  @override
  String get topUpStatusApproved => 'Approved';

  @override
  String get topUpStatusRejected => 'Rejected';

  @override
  String get topUpRejectionReason => 'Rejection Reason';

  @override
  String get topUpEmptyHistory => 'No top-up requests yet.';

  @override
  String get topUpErrorInvalidAmount =>
      'Please enter a valid amount greater than 0.';

  @override
  String get topUpErrorSelectMethod => 'Please select a payment method.';

  @override
  String get topUpErrorEnterReference =>
      'Please enter the transaction reference.';

  @override
  String get topUpErrorAttachProof =>
      'Please upload a payment screenshot receipt.';

  @override
  String get topUpErrorDuplicateRef =>
      'A top-up request with this payment reference is already active or approved.';

  @override
  String get topUpErrorUploadFailed =>
      'Failed to upload payment proof. Please try again.';

  @override
  String get topUpErrorNotFound => 'Top-up request not found.';

  @override
  String get topUpErrorAlreadyReviewed =>
      'This top-up request has already been reviewed.';

  @override
  String get continueAction => 'Continue';

  @override
  String get backAction => 'Back';
}
