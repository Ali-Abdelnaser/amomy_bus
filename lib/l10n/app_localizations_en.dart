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
  String get homeFastDirect => 'FAST & DIRECT';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get notificationCategories => 'Notification Categories';

  @override
  String get serviceUpdatesTitle => 'Service & General Updates';

  @override
  String get serviceUpdatesDescription =>
      'Important AMOMY service announcements.';

  @override
  String get bookingUpdatesTitle => 'Booking Updates';

  @override
  String get bookingUpdatesDescription =>
      'Confirmation, cancellation and seat changes.';

  @override
  String get notificationsDisabledInDevice =>
      'Notifications disabled in device settings';

  @override
  String get notificationsDisabledInDeviceDescription =>
      'Please enable notifications in your device settings to receive trip and wallet alerts.';

  @override
  String get enableInDeviceSettings => 'Enable in Device Settings';

  @override
  String get allNotifications => 'All Notifications';

  @override
  String get allNotificationsDescription =>
      'Master toggle for all push notifications';

  @override
  String get notificationTestLabTitle => 'Notification Test Lab';

  @override
  String get notificationTestLabLocalTitle => 'Local Test';

  @override
  String get notificationTestLabLocalSubtitle =>
      'Tests local presentation on this device only.';

  @override
  String get notificationTestLabLocalButton => 'Local Test';

  @override
  String get notificationTestLabRemoteTitle => 'Remote FCM Test';

  @override
  String get notificationTestLabRemoteSubtitle =>
      'Requests a real push through FCM and APNs.';

  @override
  String get notificationTestLabRemoteButton => 'Remote Push Test';

  @override
  String get notificationTestLabLocalShown =>
      'Local notification shown on this device.';

  @override
  String get notificationTestLabRemoteRequested =>
      'Push requested. Put the app in the background or lock the phone.';

  @override
  String get notificationTestLabRequestFailed =>
      'Unable to request remote push.';

  @override
  String get seatStatusCurrent => 'Current Seat';

  @override
  String get seatStatusBookedMale => 'Booked (M)';

  @override
  String get seatStatusBookedFemale => 'Booked (F)';

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
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInWithApple => 'Continue with Apple';

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
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get wrongEmailPrompt => 'Wrong email?';

  @override
  String get changeEmailAction => 'Change email';

  @override
  String get otpInvalid => 'The verification code is incorrect.';

  @override
  String get otpExpired => 'This code has expired. Request a new one.';

  @override
  String get otpRateLimited => 'Please wait before requesting another code.';

  @override
  String get otpNetworkError =>
      'Couldn\'t verify the code. Check your connection and try again.';

  @override
  String get selectDateTitle => 'Select Date';

  @override
  String get confirmDate => 'Confirm Date';

  @override
  String get dayColumnLabel => 'Day';

  @override
  String get monthColumnLabel => 'Month';

  @override
  String get yearColumnLabel => 'Year';

  @override
  String get completeProfileTitle => 'Complete Your Profile';

  @override
  String get completeProfileSubtitle =>
      'Please provide your details to complete your account setup';

  @override
  String get saveAndContinue => 'Save & Continue';

  @override
  String get profileUpdateFailed =>
      'Couldn\'t save your changes. Please try again.';

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
  String get noUpcomingTrip => 'No upcoming trips';

  @override
  String get noUpcomingTripSubtitle =>
      'Book a seat whenever a trip is available.';

  @override
  String get qr => 'QR';

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
  String get noTransactionsSubtitle => 'Your points activity will appear here.';

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
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmMessage =>
      'Are you sure you want to sign out of your account?';

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
  String get bookingTicketTime => 'TIME';

  @override
  String get bookingTicketSeat => 'SEAT';

  @override
  String get bookingTicketFees => 'FEES';

  @override
  String get bookingSuccessMyTrips => 'My Trips';

  @override
  String get bookingSuccessGoHome => 'Go to Home';

  @override
  String get qrTicketInstruction =>
      'Present this QR code to the driver or scanner upon boarding.';

  @override
  String get viewMyTrips => 'View My Trips';

  @override
  String get mitFadalaStopName => 'Mit Fadala';

  @override
  String departureBusAtFirstStop(Object stopName) {
    return 'Bus at $stopName';
  }

  @override
  String get firstStopLabel => 'First stop';

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

  @override
  String get announcements => 'Announcements';

  @override
  String get announcementBadge => 'Announcement';

  @override
  String get offerBadge => 'Offer';

  @override
  String get viewTicket => 'View Ticket';

  @override
  String get yourActivity => 'Your Activity';

  @override
  String get tripsThisMonth => 'Trips This Month';

  @override
  String get completedTrips => 'Completed Trips';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get pointsSpentThisMonth => 'Points Spent This Month';

  @override
  String get missedTrips => 'Missed Trips';

  @override
  String get noMissedTripsMessage => 'No missed trips this month.';

  @override
  String get allTime => 'All Time';

  @override
  String get thisMonth => 'This Month';

  @override
  String get selectBoardingStop => 'Select Boarding Stop';

  @override
  String get boardingStop => 'Boarding Stop';

  @override
  String get noStopsAvailable => 'No boarding stops available at this time';

  @override
  String get chooseSeatAgain => 'Choose Seat Again';

  @override
  String get holdExpiredMessage =>
      'Your seat hold has expired. Please choose a seat again.';

  @override
  String seatHeldFor(String time) {
    return 'Seat held for $time';
  }

  @override
  String get bookingSummaryTitle => 'Booking Summary';

  @override
  String get totalFare => 'Total';

  @override
  String get availableBalanceLabel => 'Available balance';

  @override
  String get afterBookingLabel => 'After booking';

  @override
  String notEnoughPointsDeficit(int deficit) {
    return 'Not enough points. You need $deficit more points to complete this booking.';
  }

  @override
  String get reviewTicketNotice =>
      'You can review your ticket in My Trips after booking.';

  @override
  String get fromStop => 'From';

  @override
  String get toStop => 'To';

  @override
  String get departureTimeTitle => 'Departure Time';

  @override
  String get departureSelected => 'Selected';

  @override
  String get departureSelectedTrip => 'Selected Trip';

  @override
  String get departureAvailable => 'Available';

  @override
  String get departureFullyBooked => 'Fully booked';

  @override
  String get departureAvailableNow => 'Available now';

  @override
  String get fewSeatsLeft => 'Few seats left';

  @override
  String get alreadyBookedTrip =>
      'You already have an active booking for this trip.';

  @override
  String seatNumberSelected(String seatNumber) {
    return 'Seat $seatNumber selected';
  }

  @override
  String get noMoreAvailableTrips => 'No more available trips for today';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get noTransactionsTitle => 'No transactions yet';

  @override
  String get cardTravelBalance => 'Your travel balance';

  @override
  String get amomyWallet => 'AMOMY Wallet';

  @override
  String get txTypeTrip => 'Trip Booking';

  @override
  String get txTypeTripBooking => 'Trip Booking';

  @override
  String get txTypeExtraSeat => 'Extra Seat';

  @override
  String get txTypeRefund => 'Refund';

  @override
  String get txTypeTopUp => 'Points Top-up';

  @override
  String get txTypePointsTopup => 'Points Top-up';

  @override
  String get txTypeExtraPoints => 'Extra Points';

  @override
  String get txTypeSubscriptionPoints => 'Subscription Points';

  @override
  String get txTypePointsExpired => 'Points Expired';

  @override
  String get txTypeBonus => 'Bonus';

  @override
  String get txTypeGift => 'Gift';

  @override
  String get txTypeWelcomeGift => 'Welcome Gift';

  @override
  String get txTypeCampaignGift => 'Gift';

  @override
  String get txTypeAdjustment => 'Balance Adjustment';

  @override
  String get txTypeBalanceAdjustment => 'Balance Adjustment';

  @override
  String get txTypePointsAdjustment => 'Points Adjustment';

  @override
  String get txTypeTransaction => 'Transaction';

  @override
  String seatNumberLabel(String seat) {
    return 'Seat $seat';
  }

  @override
  String get loadMoreTransactions => 'Load older transactions';

  @override
  String get ptsUnit => 'PTS';

  @override
  String get howManyPointsToAdd => 'How many points would you like to add?';

  @override
  String get minTopupNotice => 'Minimum top-up is 200 Points.';

  @override
  String get customAmount => 'Custom Amount';

  @override
  String pointsEquivalentEgp(String points, String egp) {
    return '$points Points = $egp EGP';
  }

  @override
  String get mobileCash => 'Mobile Cash';

  @override
  String get transferAmount => 'Transfer Amount';

  @override
  String get transferTo => 'Transfer To';

  @override
  String get copyNumber => 'Copy';

  @override
  String get numberCopied => 'Number copied to clipboard';

  @override
  String get instructionStep1 => '1. Open your mobile wallet.';

  @override
  String get instructionStep2 => '2. Transfer the exact amount.';

  @override
  String get instructionStep3 => '3. Keep the confirmation message.';

  @override
  String get instructionStep4 =>
      '4. Return here and submit the transfer details.';

  @override
  String get iveTransferredCta => 'I\'ve Made the Transfer';

  @override
  String get senderPhoneLabel => 'Sender Phone Number';

  @override
  String get senderPhoneHint => '01XXXXXXXXX';

  @override
  String get senderPhoneInvalid =>
      'Please enter a valid Egyptian mobile number (01XXXXXXXXX)';

  @override
  String get transferReferenceLabel => 'Reference / Transaction ID';

  @override
  String get transferReferenceOptional => 'Optional if not provided by wallet';

  @override
  String get transferDateTimeLabel => 'Transfer Date & Time';

  @override
  String get paymentScreenshotLabel => 'Payment Screenshot';

  @override
  String get tapToUploadScreenshot => 'Tap to upload screenshot';

  @override
  String get screenshotAttached => 'Receipt attached';

  @override
  String get submitDetailsAction => 'Submit Transfer Details';

  @override
  String get paymentSubmittedTitle => 'Payment Submitted';

  @override
  String get paymentUnderReviewSubtitle => 'Your transfer is under review.';

  @override
  String get statusPendingReview => 'Under Review';

  @override
  String get statusAwaitingPayment => 'Awaiting Payment';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get requestIdLabel => 'Request ID';

  @override
  String get backToWalletCta => 'Back to Wallet';

  @override
  String get stepPoints => 'Points';

  @override
  String get stepPayment => 'Payment';

  @override
  String get stepConfirm => 'Confirm';

  @override
  String get vodafoneCash => 'Vodafone Cash';

  @override
  String get instapay => 'InstaPay';

  @override
  String get choosePaymentMethod => 'Choose payment method';

  @override
  String get instapayAccount => 'InstaPay Account';

  @override
  String get pendingPoints => 'Pending Points';

  @override
  String get paymentCouldNotBeVerified => 'Payment couldn\'t be verified';

  @override
  String get resubmit => 'Resubmit';

  @override
  String get resubmitPaymentTitle => 'Resubmit Payment';

  @override
  String get resubmitForReview => 'Resubmit for Review';

  @override
  String get paymentResubmittedTitle => 'Payment Resubmitted';

  @override
  String get submittedOn => 'Submitted';

  @override
  String get viewAllPendingTopUps => 'View all pending top-ups';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get serviceUpdatesDesc => 'Important AMOMY service announcements.';

  @override
  String get bookingUpdatesDesc =>
      'Confirmation, cancellation and seat changes.';

  @override
  String get walletUpdatesTitle => 'Wallet & Top-up';

  @override
  String get walletUpdatesDesc =>
      'Top-up approvals, rejections and point transactions.';

  @override
  String get tripUpdatesTitle => 'Trip & Bus Tracking';

  @override
  String get tripUpdatesDesc =>
      'Trip updates and alerts when your bus is approaching.';

  @override
  String get notificationsDisabledOs =>
      'Notifications are disabled in device settings.';

  @override
  String get openDeviceSettings => 'Open Device Settings';

  @override
  String get todayHeader => 'TODAY';

  @override
  String get earlierHeader => 'EARLIER';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profilePreferencesSection => 'Preferences';

  @override
  String get profileHelpSupportSection => 'Help & Support';

  @override
  String get profileAboutLegalSection => 'About & Legal';

  @override
  String get supportCenter => 'Support Center';

  @override
  String get aboutAmomyApp => 'About AMOMY App';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromPhotos => 'Choose from Photos';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get avatarUpdatedSuccess => 'Profile photo updated successfully';

  @override
  String get avatarRemovedSuccess => 'Profile photo removed successfully';

  @override
  String get avatarUpdateFailed => 'Failed to update profile photo';

  @override
  String get avatarRemoveFailed => 'Failed to remove profile photo';

  @override
  String get supportHeroTitle => 'How can we help?';

  @override
  String get supportHeroSubtitle =>
      'We are here to assist you with your trips, bookings, and account.';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get callUs => 'Call Us';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get faqQuestion1 => 'How do I book a seat on a bus?';

  @override
  String get faqAnswer1 =>
      'Choose your departure and destination stops, select your trip time, and pick an available seat directly on the bus map.';

  @override
  String get faqQuestion2 => 'How does the Points wallet work?';

  @override
  String get faqAnswer2 =>
      'Your wallet uses points where 1 Point = 1 EGP. You can top up your balance via Vodafone Cash or InstaPay.';

  @override
  String get faqQuestion3 => 'How do I board the bus?';

  @override
  String get faqAnswer3 =>
      'Show your digital QR ticket from the app to the driver or staff member when boarding.';

  @override
  String get aboutAppDescription =>
      'AMOMY Bus is a modern passenger transportation app designed for reliable daily commuting in Egypt.';

  @override
  String get aboutFeature1 => 'View scheduled trips and routes';

  @override
  String get aboutFeature2 => 'Reserve available seats in real time';

  @override
  String get aboutFeature3 => 'Manage your bookings and trip history';

  @override
  String get aboutFeature4 => 'Top up and pay with Points wallet';

  @override
  String get aboutFeature5 => 'Access digital QR tickets for quick boarding';

  @override
  String get aboutFeature6 =>
      'Receive real-time trip and service notifications';

  @override
  String get aboutFeature7 => 'Track supported buses during operating hours';

  @override
  String get developerSection => 'Developer';

  @override
  String get developerNameLabel => 'Developer';

  @override
  String get developerEmailLabel => 'Contact Email';

  @override
  String get developerWebsiteLabel => 'Website';

  @override
  String get developerLinkedInLabel => 'LinkedIn';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get allRightsReserved => 'All rights reserved.';

  @override
  String get privacyPolicyUrl => 'https://amomy.com/privacy-policy';

  @override
  String get termsAndConditionsUrl => 'https://amomy.com/terms-and-conditions';

  @override
  String get noTripsAvailableToday => 'No trips available today';

  @override
  String get noMoreTripsAvailableToday => 'No more trips available today';

  @override
  String get trackingOffline => 'OFFLINE';

  @override
  String get trackingLive => 'LIVE';

  @override
  String get trackingAssignmentPending => 'Bus assignment pending';

  @override
  String get trackingLocationUnavailable => 'Location temporarily unavailable';

  @override
  String get trackingUnavailable => 'Tracking unavailable';

  @override
  String get trackingProgressUnavailable =>
      'Stop progress temporarily unavailable';

  @override
  String get trackingTripNotActive => 'Trip tracking is not active';

  @override
  String get trackingLastStop => 'Last Stop';

  @override
  String trackingReached(String time) {
    return 'Reached $time';
  }

  @override
  String get trackingCurrentStop => 'Current Stop';

  @override
  String get trackingNextStop => 'Next Stop';

  @override
  String get trackingEtaUnavailable => 'ETA unavailable';

  @override
  String get trackingConfirmedTitle => 'Your trip is confirmed';

  @override
  String get trackingWaitingAssignmentSubtitle =>
      'Live tracking will be available when your bus is assigned.';

  @override
  String get trackingReadyTitle => 'Ready for your trip';

  @override
  String get trackingWaitingStartSubtitle =>
      'Live tracking will start when the driver starts the trip.';

  @override
  String get trackingUpdatingBusTitle => 'Updating your bus';

  @override
  String get trackingReassignmentPendingSubtitle =>
      'Live tracking will resume shortly.';

  @override
  String get trackingGpsStaleTitle => 'Bus location is temporarily delayed';

  @override
  String get trackingGpsOfflineTitle =>
      'Live location is temporarily unavailable';

  @override
  String get trackingGpsOfflineSubtitle =>
      'The trip is active. We\'re waiting for a new location update.';

  @override
  String get trackingProgressionSyncing => 'Updating trip progress…';

  @override
  String get trackingLastKnownLocation => 'Last known location';

  @override
  String get trackingPendingPill => 'PENDING';

  @override
  String get trackingReadyPill => 'READY';

  @override
  String get trackingUpdatingPill => 'UPDATING';

  @override
  String get trackingDelayedPill => 'DELAYED';

  @override
  String get trackingSyncingPill => 'SYNCING';

  @override
  String get trackingCompletedPill => 'COMPLETED';

  @override
  String get trackingCancelledPill => 'CANCELLED';

  @override
  String get trackingEndedPill => 'ENDED';

  @override
  String get trackingUnavailablePill => 'UNAVAILABLE';

  @override
  String get trackingMapDisabledTitle => 'Live map is currently unavailable';

  @override
  String get trackingMapDisabledSubtitle =>
      'Live location display has been disabled by the administration.';

  @override
  String get trackingBusHiddenTitle =>
      'Live location is unavailable for this trip';

  @override
  String get trackingBusHiddenSubtitle =>
      'Live bus location display is currently turned off.';

  @override
  String get trackingNoTripSelectedTitle => 'Select a trip to view tracking';

  @override
  String get trackingNoTripSelectedSubtitle =>
      'You can open live tracking from your trip details.';

  @override
  String get trackingViewMyTripsAction => 'View My Trips';

  @override
  String get trackingLastUpdatedJustNow => 'Updated just now';

  @override
  String trackingLastUpdatedSeconds(int seconds) {
    return 'Updated $seconds seconds ago';
  }

  @override
  String trackingLastUpdatedMinutes(int minutes) {
    return 'Last updated $minutes min ago';
  }

  @override
  String get trackingResumesMidday => 'Tracking resumes at 1:00 PM';

  @override
  String get trackingResumesTomorrow => 'Tracking resumes tomorrow at 8:00 AM';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusFinished => 'Finished';

  @override
  String get bookingStatusNoShow => 'No Show';

  @override
  String get bookingStatusPending => 'Pending';

  @override
  String get errorHoldExpired =>
      'Seat hold expired. Please select a seat again.';

  @override
  String get errorBookingClosed => 'Booking for this trip is closed.';

  @override
  String get errorCancellationWindowClosed => 'Cancellation period has ended.';

  @override
  String get errorChangeSeatWindowClosed => 'Seat change period has ended.';

  @override
  String get errorServiceDayOff => 'No trips available today.';

  @override
  String get changeSeat => 'Change Seat';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get viewLiveMap => 'View Live Map';

  @override
  String get viewTrip => 'View Trip';

  @override
  String get extraSeat => 'Extra Seat';

  @override
  String get addExtraSeat => 'Add Extra Seat';

  @override
  String get digitalBoardingPass => 'Digital Boarding Pass';

  @override
  String get accessBlockedTitle => 'Access Restricted';

  @override
  String get deviceBlockedMessage =>
      'This device has been blocked from using AMOMY Bus';

  @override
  String get accountSuspendedMessage => 'This account has been suspended';

  @override
  String accountSuspendedUntilMessage(String date) {
    return 'Your account is suspended until $date';
  }

  @override
  String get logout => 'Sign Out';

  @override
  String get singleTrip => 'One-way';

  @override
  String get roundTrip => 'Round Trip';

  @override
  String get roundTripDiscountBadge => '15% OFF';

  @override
  String get returnDepartureTimeTitle => 'Return Time';

  @override
  String get selectOutboundSeat => 'Select Outbound Seat';

  @override
  String get selectReturnSeat => 'Select Return Seat';

  @override
  String get proceedToReturnSeat => 'Continue to Return Seat';

  @override
  String get outboundFareLabel => 'Outbound Fare';

  @override
  String get returnFareLabel => 'Return Fare';

  @override
  String get subtotalFareLabel => 'Subtotal';

  @override
  String get roundTripDiscountLabel => 'Round Trip Discount 15%';

  @override
  String get totalAfterDiscountLabel => 'Total after discount';

  @override
  String get confirmRoundTripBooking => 'Confirm Round Trip Booking';

  @override
  String get roundTripSuccessTitle => 'Round Trip Booked Successfully';

  @override
  String get outboundTimeLabel => 'Outbound Time';

  @override
  String get outboundSeatLabel => 'Outbound Seat';

  @override
  String get returnTimeLabel => 'Return Time';

  @override
  String get returnSeatLabel => 'Return Seat';

  @override
  String savedPointsNotice(int points) {
    return 'You saved $points points';
  }

  @override
  String get cancelRoundTripTitle => 'Cancel Round Trip Booking';

  @override
  String get cancelRoundTripMessage =>
      'This booking is part of a 15% discounted Round Trip bundle. Cancelling will cancel both Outbound and Return trips together.';

  @override
  String get cancelBothLegsCta => 'Cancel Both Trips & Refund';

  @override
  String get roundTripCancellationClosed =>
      'Cancellation is closed after departure cutoff or if either trip has been used.';

  @override
  String get noReturnTripsAvailable => 'No return trips available today';

  @override
  String get errorRoundTripMustStartWithOutbound =>
      'Round Trip booking is only available when starting from the Outbound direction.';

  @override
  String get errorInvalidRoundTripDirections =>
      'Outbound and Return trips must be in opposite directions.';

  @override
  String get errorRoundTripSameDayRequired =>
      'Outbound and Return trips must be on the same service day.';

  @override
  String get errorReturnMustBeAfterOutbound =>
      'Return trip departure must be after Outbound departure.';

  @override
  String get errorRoundTripDiscountAlreadyUsedToday =>
      'You have already used your daily round-trip discount.';

  @override
  String get errorRoundTripRequiresUnbookedTrips =>
      'You already have a booking on one of the selected trips.';

  @override
  String get errorRoundTripHoldAlreadyActive =>
      'You already have an active round-trip hold.';

  @override
  String get errorRoundTripHoldNotFound => 'Round-trip hold not found.';

  @override
  String get errorRoundTripHoldInvalid =>
      'Round-trip hold is invalid or expired.';

  @override
  String get errorReturnSeatRequired => 'Please select a return seat first.';

  @override
  String get errorRoundTripCancellationWindowClosed =>
      'Cancellation window for this round-trip bundle has closed.';

  @override
  String get errorRoundTripAlreadyUsed =>
      'Cannot cancel after a trip in the bundle has been checked-in or completed.';

  @override
  String get errorRoundTripBundleNotCancellable =>
      'This bundle is not cancellable.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet =>
      'No internet connection. Check your network and try again.';

  @override
  String get errorTimeout => 'The connection took too long. Please try again.';

  @override
  String get errorServerUnreachable =>
      'We couldn\'t connect to the server right now. Please try again shortly.';

  @override
  String get errorNetworkProblem =>
      'A network problem occurred. Please try again.';

  @override
  String get errorInvalidLogin => 'Incorrect email or password.';

  @override
  String get errorEmailNotConfirmed => 'Please confirm your email first.';

  @override
  String get errorUserAlreadyExists =>
      'An account with this email already exists.';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorWeakPassword =>
      'Your password is too weak. Please choose a stronger password.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorNotAuthenticated => 'Please sign in to continue.';

  @override
  String get errorRateLimited => 'Too many attempts. Please try again shortly.';

  @override
  String get errorOtpInvalid => 'The verification code is incorrect.';

  @override
  String get errorOtpExpired =>
      'The verification code has expired. Request a new one.';

  @override
  String get errorPasswordReset =>
      'We couldn\'t send the password reset link. Please try again.';

  @override
  String get errorGoogleSignInCancelled => 'Google sign-in was cancelled.';

  @override
  String get errorGoogleSignInFailed =>
      'We couldn\'t sign you in with Google. Please try again.';

  @override
  String get errorAuthUnknown =>
      'Something went wrong while signing in. Please try again.';

  @override
  String get errorTrackingAccessDenied =>
      'You are not authorized to track this trip.';

  @override
  String get errorWalletNotFound => 'Wallet not found. Please contact support.';

  @override
  String get errorSeatAlreadyBooked =>
      'The selected seat is no longer available. Please select another seat.';

  @override
  String get errorTripCancelled => 'This trip has been cancelled.';

  @override
  String get errorTripCompleted => 'This trip is already completed.';

  @override
  String get errorBookingNotBoardable =>
      'Booking is not eligible for boarding now.';

  @override
  String get errorAlreadyCheckedIn => 'Already checked in.';

  @override
  String get errorTooEarly => 'Trip time is too early.';

  @override
  String get errorWrongTrip => 'Ticket is for another trip.';

  @override
  String get errorInvalidToken => 'Invalid ticket code.';
}
