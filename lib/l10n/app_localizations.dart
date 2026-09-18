import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Amomy Bus'**
  String get appName;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @homeFastDirect.
  ///
  /// In en, this message translates to:
  /// **'FAST & DIRECT'**
  String get homeFastDirect;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationCategories.
  ///
  /// In en, this message translates to:
  /// **'Notification Categories'**
  String get notificationCategories;

  /// No description provided for @serviceUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Service & General Updates'**
  String get serviceUpdatesTitle;

  /// No description provided for @serviceUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Important AMOMY service announcements.'**
  String get serviceUpdatesDescription;

  /// No description provided for @bookingUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Updates'**
  String get bookingUpdatesTitle;

  /// No description provided for @bookingUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Confirmation, cancellation and seat changes.'**
  String get bookingUpdatesDescription;

  /// No description provided for @notificationsDisabledInDevice.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled in device settings'**
  String get notificationsDisabledInDevice;

  /// No description provided for @notificationsDisabledInDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications in your device settings to receive trip and wallet alerts.'**
  String get notificationsDisabledInDeviceDescription;

  /// No description provided for @enableInDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable in Device Settings'**
  String get enableInDeviceSettings;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get allNotifications;

  /// No description provided for @allNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Master toggle for all push notifications'**
  String get allNotificationsDescription;

  /// No description provided for @notificationTestLabTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Test Lab'**
  String get notificationTestLabTitle;

  /// No description provided for @notificationTestLabLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Test'**
  String get notificationTestLabLocalTitle;

  /// No description provided for @notificationTestLabLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tests local presentation on this device only.'**
  String get notificationTestLabLocalSubtitle;

  /// No description provided for @notificationTestLabLocalButton.
  ///
  /// In en, this message translates to:
  /// **'Local Test'**
  String get notificationTestLabLocalButton;

  /// No description provided for @notificationTestLabRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote FCM Test'**
  String get notificationTestLabRemoteTitle;

  /// No description provided for @notificationTestLabRemoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requests a real push through FCM and APNs.'**
  String get notificationTestLabRemoteSubtitle;

  /// No description provided for @notificationTestLabRemoteButton.
  ///
  /// In en, this message translates to:
  /// **'Remote Push Test'**
  String get notificationTestLabRemoteButton;

  /// No description provided for @notificationTestLabLocalShown.
  ///
  /// In en, this message translates to:
  /// **'Local notification shown on this device.'**
  String get notificationTestLabLocalShown;

  /// No description provided for @notificationTestLabRemoteRequested.
  ///
  /// In en, this message translates to:
  /// **'Push requested. Put the app in the background or lock the phone.'**
  String get notificationTestLabRemoteRequested;

  /// No description provided for @notificationTestLabRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to request remote push.'**
  String get notificationTestLabRequestFailed;

  /// No description provided for @seatStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Seat'**
  String get seatStatusCurrent;

  /// No description provided for @seatStatusBookedMale.
  ///
  /// In en, this message translates to:
  /// **'Booked (M)'**
  String get seatStatusBookedMale;

  /// No description provided for @seatStatusBookedFemale.
  ///
  /// In en, this message translates to:
  /// **'Booked (F)'**
  String get seatStatusBookedFemale;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorOccurred;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your trips and tickets'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get registerNow;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Amomy to travel easily and comfortably'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed Mohamed'**
  String get fullNameHint;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'01012345678'**
  String get phoneHint;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select Date of Birth'**
  String get selectDateOfBirth;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInNow.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInNow;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit verification code to'**
  String get verifyEmailSubtitle;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code to verify your account'**
  String get enterCode;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyButton;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email / Back'**
  String get changeEmail;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @wrongEmailPrompt.
  ///
  /// In en, this message translates to:
  /// **'Wrong email?'**
  String get wrongEmailPrompt;

  /// No description provided for @changeEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmailAction;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'The verification code is incorrect.'**
  String get otpInvalid;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new one.'**
  String get otpExpired;

  /// No description provided for @otpRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Please wait before requesting another code.'**
  String get otpRateLimited;

  /// No description provided for @otpNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify the code. Check your connection and try again.'**
  String get otpNetworkError;

  /// No description provided for @selectDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDateTitle;

  /// No description provided for @confirmDate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Date'**
  String get confirmDate;

  /// No description provided for @dayColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayColumnLabel;

  /// No description provided for @monthColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthColumnLabel;

  /// No description provided for @yearColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearColumnLabel;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please provide your details to complete your account setup'**
  String get completeProfileSubtitle;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes. Please try again.'**
  String get profileUpdateFailed;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address to receive password recovery instructions'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetInstructions.
  ///
  /// In en, this message translates to:
  /// **'Send Recovery Instructions'**
  String get sendResetInstructions;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToLogin;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password with at least 8 characters'**
  String get resetPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully. Please sign in.'**
  String get passwordUpdatedSuccess;

  /// No description provided for @resetEmailSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recovery instructions sent. Please check your inbox.'**
  String get resetEmailSentSuccess;

  /// No description provided for @homePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Passenger Home'**
  String get homePlaceholderTitle;

  /// No description provided for @authenticatedAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get authenticatedAs;

  /// No description provided for @activeRoles.
  ///
  /// In en, this message translates to:
  /// **'Active Roles'**
  String get activeRoles;

  /// No description provided for @cashPoints.
  ///
  /// In en, this message translates to:
  /// **'Cash Points'**
  String get cashPoints;

  /// No description provided for @subscriptionPoints.
  ///
  /// In en, this message translates to:
  /// **'Subscription Points'**
  String get subscriptionPoints;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Egyptian phone number (01xxxxxxxxx)'**
  String get validationPhoneInvalid;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordLength;

  /// No description provided for @validationPasswordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one letter and one number'**
  String get validationPasswordComplexity;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// No description provided for @validationOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit verification code'**
  String get validationOtpInvalid;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @languageSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'عربي'**
  String get languageSwitchLabel;

  /// No description provided for @onboardingBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Your Ride Easily'**
  String get onboardingBookingTitle;

  /// No description provided for @onboardingBookingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your trip time and preferred seat in just a few taps.'**
  String get onboardingBookingSubtitle;

  /// No description provided for @onboardingTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Your Bus Live'**
  String get onboardingTrackingTitle;

  /// No description provided for @onboardingTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow your bus location and arrival time in real time.'**
  String get onboardingTrackingSubtitle;

  /// No description provided for @onboardingBoardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Board Quickly & Securely'**
  String get onboardingBoardingTitle;

  /// No description provided for @onboardingBoardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your QR code or card for fast and simple boarding.'**
  String get onboardingBoardingSubtitle;

  /// No description provided for @completeProfileReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileReminderTitle;

  /// No description provided for @completeProfileReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finish your profile to access all AMOMY services.'**
  String get completeProfileReminderSubtitle;

  /// No description provided for @completeNow.
  ///
  /// In en, this message translates to:
  /// **'Complete now'**
  String get completeNow;

  /// No description provided for @bookingGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile first'**
  String get bookingGuardTitle;

  /// No description provided for @bookingGuardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need your phone number, gender, and date of birth before booking your trip.'**
  String get bookingGuardSubtitle;

  /// No description provided for @completeProfileCta.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfileCta;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get navMyTrips;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @pointsBalance.
  ///
  /// In en, this message translates to:
  /// **'Points Balance'**
  String get pointsBalance;

  /// No description provided for @pointsUnit.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsUnit;

  /// No description provided for @addPoints.
  ///
  /// In en, this message translates to:
  /// **'Add Points'**
  String get addPoints;

  /// No description provided for @walletDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get walletDetails;

  /// No description provided for @cashPointsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Cash points'**
  String get cashPointsPrefix;

  /// No description provided for @subscriptionPointsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Subscription points'**
  String get subscriptionPointsPrefix;

  /// No description provided for @bookRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Your Ride'**
  String get bookRideTitle;

  /// No description provided for @bookRideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your departure time and preferred seat.'**
  String get bookRideSubtitle;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @upcomingTrip.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trip'**
  String get upcomingTrip;

  /// No description provided for @noUpcomingTrip.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips'**
  String get noUpcomingTrip;

  /// No description provided for @noUpcomingTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a seat whenever a trip is available.'**
  String get noUpcomingTripSubtitle;

  /// No description provided for @qr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get qr;

  /// No description provided for @bookTripCta.
  ///
  /// In en, this message translates to:
  /// **'Book a Ride'**
  String get bookTripCta;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @actionAddPoints.
  ///
  /// In en, this message translates to:
  /// **'Add Points'**
  String get actionAddPoints;

  /// No description provided for @actionMyTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get actionMyTrips;

  /// No description provided for @actionSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get actionSubscriptions;

  /// No description provided for @actionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get actionSupport;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @upcomingTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @noTripsFound.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsFound;

  /// No description provided for @noTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you book a trip, it will appear right here.'**
  String get noTripsSubtitle;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your points activity will appear here.'**
  String get noTransactionsSubtitle;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @aboutAmomy.
  ///
  /// In en, this message translates to:
  /// **'About AMOMY'**
  String get aboutAmomy;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get signOutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @featureUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Feature Under Development'**
  String get featureUnderDevelopment;

  /// No description provided for @bookingComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Trip booking and seat selection is currently under development.'**
  String get bookingComingSoonDesc;

  /// No description provided for @subscriptionsComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans will be available soon.'**
  String get subscriptionsComingSoonDesc;

  /// No description provided for @supportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'AMOMY Customer Support'**
  String get supportDialogTitle;

  /// No description provided for @supportDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Our support team is available 24/7 to assist you with your trips and account.'**
  String get supportDialogDesc;

  /// No description provided for @quickBooking.
  ///
  /// In en, this message translates to:
  /// **'Fast & Direct'**
  String get quickBooking;

  /// No description provided for @directionOutbound.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get directionOutbound;

  /// No description provided for @directionReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get directionReturn;

  /// No description provided for @selectDirection.
  ///
  /// In en, this message translates to:
  /// **'Select Direction'**
  String get selectDirection;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @selectSeat.
  ///
  /// In en, this message translates to:
  /// **'Select Seat'**
  String get selectSeat;

  /// No description provided for @reviewBooking.
  ///
  /// In en, this message translates to:
  /// **'Review Booking'**
  String get reviewBooking;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @seatsAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} seats available'**
  String seatsAvailableCount(int count);

  /// No description provided for @seatStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get seatStatusAvailable;

  /// No description provided for @seatStatusHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get seatStatusHeld;

  /// No description provided for @seatStatusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get seatStatusBooked;

  /// No description provided for @seatStatusSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get seatStatusSelected;

  /// No description provided for @driverFront.
  ///
  /// In en, this message translates to:
  /// **'Front / Driver'**
  String get driverFront;

  /// No description provided for @holdCountdown.
  ///
  /// In en, this message translates to:
  /// **'Seat hold expires in {time}'**
  String holdCountdown(String time);

  /// No description provided for @holdExpiredNotice.
  ///
  /// In en, this message translates to:
  /// **'Your seat hold has expired. Please select a seat again.'**
  String get holdExpiredNotice;

  /// No description provided for @seatUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'This seat is no longer available. Please select another seat.'**
  String get seatUnavailableNotice;

  /// No description provided for @insufficientPointsNotice.
  ///
  /// In en, this message translates to:
  /// **'Insufficient points balance. Please recharge your points to continue.'**
  String get insufficientPointsNotice;

  /// No description provided for @bookingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed!'**
  String get bookingSuccessTitle;

  /// No description provided for @bookingSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your trip seat is successfully reserved.'**
  String get bookingSuccessSubtitle;

  /// No description provided for @bookingTicketTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get bookingTicketTime;

  /// No description provided for @bookingTicketSeat.
  ///
  /// In en, this message translates to:
  /// **'SEAT'**
  String get bookingTicketSeat;

  /// No description provided for @bookingTicketFees.
  ///
  /// In en, this message translates to:
  /// **'FEES'**
  String get bookingTicketFees;

  /// No description provided for @bookingSuccessMyTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get bookingSuccessMyTrips;

  /// No description provided for @bookingSuccessGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get bookingSuccessGoHome;

  /// No description provided for @qrTicketInstruction.
  ///
  /// In en, this message translates to:
  /// **'Present this QR code to the driver or scanner upon boarding.'**
  String get qrTicketInstruction;

  /// No description provided for @viewMyTrips.
  ///
  /// In en, this message translates to:
  /// **'View My Trips'**
  String get viewMyTrips;

  /// No description provided for @mitFadalaStopName.
  ///
  /// In en, this message translates to:
  /// **'Mit Fadala'**
  String get mitFadalaStopName;

  /// No description provided for @departureBusAtFirstStop.
  ///
  /// In en, this message translates to:
  /// **'Bus at {stopName}'**
  String departureBusAtFirstStop(Object stopName);

  /// No description provided for @firstStopLabel.
  ///
  /// In en, this message translates to:
  /// **'First stop'**
  String get firstStopLabel;

  /// No description provided for @tripDetailsDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get tripDetailsDirection;

  /// No description provided for @tripDetailsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tripDetailsDate;

  /// No description provided for @tripDetailsTime.
  ///
  /// In en, this message translates to:
  /// **'Departure Time'**
  String get tripDetailsTime;

  /// No description provided for @tripDetailsSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat Number'**
  String get tripDetailsSeat;

  /// No description provided for @tripDetailsFare.
  ///
  /// In en, this message translates to:
  /// **'Trip Fare'**
  String get tripDetailsFare;

  /// No description provided for @tripDetailsRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get tripDetailsRoute;

  /// No description provided for @tripStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tripStatusScheduled;

  /// No description provided for @tripStatusBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding'**
  String get tripStatusBoarding;

  /// No description provided for @tripStatusDeparted.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get tripStatusDeparted;

  /// No description provided for @tripStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripStatusCompleted;

  /// No description provided for @tripStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripStatusCancelled;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @pointsBalanceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available Points'**
  String get pointsBalanceAvailable;

  /// No description provided for @completeProfileToBook.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile to book trips.'**
  String get completeProfileToBook;

  /// No description provided for @topUpAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get topUpAmountTitle;

  /// No description provided for @topUpAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount in EGP'**
  String get topUpAmountHint;

  /// No description provided for @topUpPointsRatio.
  ///
  /// In en, this message translates to:
  /// **'1 EGP ≈ 1 Point'**
  String get topUpPointsRatio;

  /// No description provided for @topUpSelectMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get topUpSelectMethod;

  /// No description provided for @topUpInstructions.
  ///
  /// In en, this message translates to:
  /// **'Transfer Instructions'**
  String get topUpInstructions;

  /// No description provided for @topUpRecipientAccount.
  ///
  /// In en, this message translates to:
  /// **'Recipient Account / Number'**
  String get topUpRecipientAccount;

  /// No description provided for @topUpCopyAccount.
  ///
  /// In en, this message translates to:
  /// **'Copy Number'**
  String get topUpCopyAccount;

  /// No description provided for @topUpCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'Account number copied to clipboard'**
  String get topUpCopiedToast;

  /// No description provided for @topUpTransactionReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction Reference'**
  String get topUpTransactionReference;

  /// No description provided for @topUpTransactionReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter transaction or transfer reference'**
  String get topUpTransactionReferenceHint;

  /// No description provided for @topUpTransactionReferenceHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the transfer reference to help us verify your payment quickly.'**
  String get topUpTransactionReferenceHelper;

  /// No description provided for @topUpPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Payment Proof Screenshot'**
  String get topUpPaymentProof;

  /// No description provided for @topUpUploadScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Upload Screenshot'**
  String get topUpUploadScreenshot;

  /// No description provided for @topUpChangeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Change Screenshot'**
  String get topUpChangeScreenshot;

  /// No description provided for @topUpReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Top-Up Request'**
  String get topUpReviewTitle;

  /// No description provided for @topUpExpectedPoints.
  ///
  /// In en, this message translates to:
  /// **'Expected Cash Points'**
  String get topUpExpectedPoints;

  /// No description provided for @topUpSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Top-Up Request'**
  String get topUpSubmitButton;

  /// No description provided for @topUpSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get topUpSubmitting;

  /// No description provided for @topUpPendingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Top-up request submitted'**
  String get topUpPendingSuccessTitle;

  /// No description provided for @topUpPendingSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your request is under review.\nPoints will be added to your wallet after approval.'**
  String get topUpPendingSuccessDesc;

  /// No description provided for @topUpBackToWallet.
  ///
  /// In en, this message translates to:
  /// **'Return to Wallet'**
  String get topUpBackToWallet;

  /// No description provided for @topUpManualNotice.
  ///
  /// In en, this message translates to:
  /// **'Manual review: This is not an instant gateway. Our team verifies transfers before crediting points.'**
  String get topUpManualNotice;

  /// No description provided for @topUpHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Top-Up Requests'**
  String get topUpHistoryTitle;

  /// No description provided for @topUpStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get topUpStatusPending;

  /// No description provided for @topUpStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get topUpStatusApproved;

  /// No description provided for @topUpStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get topUpStatusRejected;

  /// No description provided for @topUpRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get topUpRejectionReason;

  /// No description provided for @topUpEmptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No top-up requests yet.'**
  String get topUpEmptyHistory;

  /// No description provided for @topUpErrorInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than 0.'**
  String get topUpErrorInvalidAmount;

  /// No description provided for @topUpErrorSelectMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method.'**
  String get topUpErrorSelectMethod;

  /// No description provided for @topUpErrorEnterReference.
  ///
  /// In en, this message translates to:
  /// **'Please enter the transaction reference.'**
  String get topUpErrorEnterReference;

  /// No description provided for @topUpErrorAttachProof.
  ///
  /// In en, this message translates to:
  /// **'Please upload a payment screenshot receipt.'**
  String get topUpErrorAttachProof;

  /// No description provided for @topUpErrorDuplicateRef.
  ///
  /// In en, this message translates to:
  /// **'A top-up request with this payment reference is already active or approved.'**
  String get topUpErrorDuplicateRef;

  /// No description provided for @topUpErrorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload payment proof. Please try again.'**
  String get topUpErrorUploadFailed;

  /// No description provided for @topUpErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Top-up request not found.'**
  String get topUpErrorNotFound;

  /// No description provided for @topUpErrorAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'This top-up request has already been reviewed.'**
  String get topUpErrorAlreadyReviewed;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @announcementBadge.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcementBadge;

  /// No description provided for @offerBadge.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offerBadge;

  /// No description provided for @viewTicket.
  ///
  /// In en, this message translates to:
  /// **'View Ticket'**
  String get viewTicket;

  /// No description provided for @yourActivity.
  ///
  /// In en, this message translates to:
  /// **'Your Activity'**
  String get yourActivity;

  /// No description provided for @tripsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Trips This Month'**
  String get tripsThisMonth;

  /// No description provided for @completedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed Trips'**
  String get completedTrips;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @pointsSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Points Spent This Month'**
  String get pointsSpentThisMonth;

  /// No description provided for @missedTrips.
  ///
  /// In en, this message translates to:
  /// **'Missed Trips'**
  String get missedTrips;

  /// No description provided for @noMissedTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'No missed trips this month.'**
  String get noMissedTripsMessage;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @selectBoardingStop.
  ///
  /// In en, this message translates to:
  /// **'Select Boarding Stop'**
  String get selectBoardingStop;

  /// No description provided for @boardingStop.
  ///
  /// In en, this message translates to:
  /// **'Boarding Stop'**
  String get boardingStop;

  /// No description provided for @noStopsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No boarding stops available at this time'**
  String get noStopsAvailable;

  /// No description provided for @chooseSeatAgain.
  ///
  /// In en, this message translates to:
  /// **'Choose Seat Again'**
  String get chooseSeatAgain;

  /// No description provided for @holdExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your seat hold has expired. Please choose a seat again.'**
  String get holdExpiredMessage;

  /// No description provided for @seatHeldFor.
  ///
  /// In en, this message translates to:
  /// **'Seat held for {time}'**
  String seatHeldFor(String time);

  /// No description provided for @bookingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Summary'**
  String get bookingSummaryTitle;

  /// No description provided for @totalFare.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalFare;

  /// No description provided for @availableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalanceLabel;

  /// No description provided for @afterBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'After booking'**
  String get afterBookingLabel;

  /// No description provided for @notEnoughPointsDeficit.
  ///
  /// In en, this message translates to:
  /// **'Not enough points. You need {deficit} more points to complete this booking.'**
  String notEnoughPointsDeficit(int deficit);

  /// No description provided for @reviewTicketNotice.
  ///
  /// In en, this message translates to:
  /// **'You can review your ticket in My Trips after booking.'**
  String get reviewTicketNotice;

  /// No description provided for @fromStop.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromStop;

  /// No description provided for @toStop.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toStop;

  /// No description provided for @departureTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Departure Time'**
  String get departureTimeTitle;

  /// No description provided for @departureSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get departureSelected;

  /// No description provided for @departureSelectedTrip.
  ///
  /// In en, this message translates to:
  /// **'Selected Trip'**
  String get departureSelectedTrip;

  /// No description provided for @departureAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get departureAvailable;

  /// No description provided for @departureFullyBooked.
  ///
  /// In en, this message translates to:
  /// **'Fully booked'**
  String get departureFullyBooked;

  /// No description provided for @departureAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get departureAvailableNow;

  /// No description provided for @fewSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'Few seats left'**
  String get fewSeatsLeft;

  /// No description provided for @alreadyBookedTrip.
  ///
  /// In en, this message translates to:
  /// **'You already have an active booking for this trip.'**
  String get alreadyBookedTrip;

  /// No description provided for @seatNumberSelected.
  ///
  /// In en, this message translates to:
  /// **'Seat {seatNumber} selected'**
  String seatNumberSelected(String seatNumber);

  /// No description provided for @noMoreAvailableTrips.
  ///
  /// In en, this message translates to:
  /// **'No more available trips for today'**
  String get noMoreAvailableTrips;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsTitle;

  /// No description provided for @cardTravelBalance.
  ///
  /// In en, this message translates to:
  /// **'Your travel balance'**
  String get cardTravelBalance;

  /// No description provided for @amomyWallet.
  ///
  /// In en, this message translates to:
  /// **'AMOMY Wallet'**
  String get amomyWallet;

  /// No description provided for @txTypeTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip Booking'**
  String get txTypeTrip;

  /// No description provided for @txTypeTripBooking.
  ///
  /// In en, this message translates to:
  /// **'Trip Booking'**
  String get txTypeTripBooking;

  /// No description provided for @txTypeExtraSeat.
  ///
  /// In en, this message translates to:
  /// **'Extra Seat'**
  String get txTypeExtraSeat;

  /// No description provided for @txTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get txTypeRefund;

  /// No description provided for @txTypeTopUp.
  ///
  /// In en, this message translates to:
  /// **'Points Top-up'**
  String get txTypeTopUp;

  /// No description provided for @txTypePointsTopup.
  ///
  /// In en, this message translates to:
  /// **'Points Top-up'**
  String get txTypePointsTopup;

  /// No description provided for @txTypeExtraPoints.
  ///
  /// In en, this message translates to:
  /// **'Extra Points'**
  String get txTypeExtraPoints;

  /// No description provided for @txTypeSubscriptionPoints.
  ///
  /// In en, this message translates to:
  /// **'Subscription Points'**
  String get txTypeSubscriptionPoints;

  /// No description provided for @txTypePointsExpired.
  ///
  /// In en, this message translates to:
  /// **'Points Expired'**
  String get txTypePointsExpired;

  /// No description provided for @txTypeBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get txTypeBonus;

  /// No description provided for @txTypeGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get txTypeGift;

  /// No description provided for @txTypeWelcomeGift.
  ///
  /// In en, this message translates to:
  /// **'Welcome Gift'**
  String get txTypeWelcomeGift;

  /// No description provided for @txTypeCampaignGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get txTypeCampaignGift;

  /// No description provided for @txTypeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance Adjustment'**
  String get txTypeAdjustment;

  /// No description provided for @txTypeBalanceAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance Adjustment'**
  String get txTypeBalanceAdjustment;

  /// No description provided for @txTypePointsAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Points Adjustment'**
  String get txTypePointsAdjustment;

  /// No description provided for @txTypeTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get txTypeTransaction;

  /// No description provided for @seatNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Seat {seat}'**
  String seatNumberLabel(String seat);

  /// No description provided for @loadMoreTransactions.
  ///
  /// In en, this message translates to:
  /// **'Load older transactions'**
  String get loadMoreTransactions;

  /// No description provided for @ptsUnit.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get ptsUnit;

  /// No description provided for @howManyPointsToAdd.
  ///
  /// In en, this message translates to:
  /// **'How many points would you like to add?'**
  String get howManyPointsToAdd;

  /// No description provided for @minTopupNotice.
  ///
  /// In en, this message translates to:
  /// **'Minimum top-up is 200 Points.'**
  String get minTopupNotice;

  /// No description provided for @customAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom Amount'**
  String get customAmount;

  /// No description provided for @pointsEquivalentEgp.
  ///
  /// In en, this message translates to:
  /// **'{points} Points = {egp} EGP'**
  String pointsEquivalentEgp(String points, String egp);

  /// No description provided for @mobileCash.
  ///
  /// In en, this message translates to:
  /// **'Mobile Cash'**
  String get mobileCash;

  /// No description provided for @transferAmount.
  ///
  /// In en, this message translates to:
  /// **'Transfer Amount'**
  String get transferAmount;

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer To'**
  String get transferTo;

  /// No description provided for @copyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyNumber;

  /// No description provided for @numberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied to clipboard'**
  String get numberCopied;

  /// No description provided for @instructionStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Open your mobile wallet.'**
  String get instructionStep1;

  /// No description provided for @instructionStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Transfer the exact amount.'**
  String get instructionStep2;

  /// No description provided for @instructionStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Keep the confirmation message.'**
  String get instructionStep3;

  /// No description provided for @instructionStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Return here and submit the transfer details.'**
  String get instructionStep4;

  /// No description provided for @iveTransferredCta.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Made the Transfer'**
  String get iveTransferredCta;

  /// No description provided for @senderPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Sender Phone Number'**
  String get senderPhoneLabel;

  /// No description provided for @senderPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'01XXXXXXXXX'**
  String get senderPhoneHint;

  /// No description provided for @senderPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Egyptian mobile number (01XXXXXXXXX)'**
  String get senderPhoneInvalid;

  /// No description provided for @transferReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference / Transaction ID'**
  String get transferReferenceLabel;

  /// No description provided for @transferReferenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional if not provided by wallet'**
  String get transferReferenceOptional;

  /// No description provided for @transferDateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer Date & Time'**
  String get transferDateTimeLabel;

  /// No description provided for @paymentScreenshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Screenshot'**
  String get paymentScreenshotLabel;

  /// No description provided for @tapToUploadScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload screenshot'**
  String get tapToUploadScreenshot;

  /// No description provided for @screenshotAttached.
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get screenshotAttached;

  /// No description provided for @submitDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Transfer Details'**
  String get submitDetailsAction;

  /// No description provided for @paymentSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Submitted'**
  String get paymentSubmittedTitle;

  /// No description provided for @paymentUnderReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your transfer is under review.'**
  String get paymentUnderReviewSubtitle;

  /// No description provided for @statusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusPendingReview;

  /// No description provided for @statusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Payment'**
  String get statusAwaitingPayment;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @requestIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestIdLabel;

  /// No description provided for @backToWalletCta.
  ///
  /// In en, this message translates to:
  /// **'Back to Wallet'**
  String get backToWalletCta;

  /// No description provided for @stepPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get stepPoints;

  /// No description provided for @stepPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get stepPayment;

  /// No description provided for @stepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get stepConfirm;

  /// No description provided for @vodafoneCash.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash'**
  String get vodafoneCash;

  /// No description provided for @instapay.
  ///
  /// In en, this message translates to:
  /// **'InstaPay'**
  String get instapay;

  /// No description provided for @choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get choosePaymentMethod;

  /// No description provided for @instapayAccount.
  ///
  /// In en, this message translates to:
  /// **'InstaPay Account'**
  String get instapayAccount;

  /// No description provided for @pendingPoints.
  ///
  /// In en, this message translates to:
  /// **'Pending Points'**
  String get pendingPoints;

  /// No description provided for @paymentCouldNotBeVerified.
  ///
  /// In en, this message translates to:
  /// **'Payment couldn\'t be verified'**
  String get paymentCouldNotBeVerified;

  /// No description provided for @resubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get resubmit;

  /// No description provided for @resubmitPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Resubmit Payment'**
  String get resubmitPaymentTitle;

  /// No description provided for @resubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Resubmit for Review'**
  String get resubmitForReview;

  /// No description provided for @paymentResubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Resubmitted'**
  String get paymentResubmittedTitle;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedOn;

  /// No description provided for @viewAllPendingTopUps.
  ///
  /// In en, this message translates to:
  /// **'View all pending top-ups'**
  String get viewAllPendingTopUps;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @serviceUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Important AMOMY service announcements.'**
  String get serviceUpdatesDesc;

  /// No description provided for @bookingUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Confirmation, cancellation and seat changes.'**
  String get bookingUpdatesDesc;

  /// No description provided for @walletUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Top-up'**
  String get walletUpdatesTitle;

  /// No description provided for @walletUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Top-up approvals, rejections and point transactions.'**
  String get walletUpdatesDesc;

  /// No description provided for @tripUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip & Bus Tracking'**
  String get tripUpdatesTitle;

  /// No description provided for @tripUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Trip updates and alerts when your bus is approaching.'**
  String get tripUpdatesDesc;

  /// No description provided for @notificationsDisabledOs.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled in device settings.'**
  String get notificationsDisabledOs;

  /// No description provided for @openDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Device Settings'**
  String get openDeviceSettings;

  /// No description provided for @todayHeader.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get todayHeader;

  /// No description provided for @earlierHeader.
  ///
  /// In en, this message translates to:
  /// **'EARLIER'**
  String get earlierHeader;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @profileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountSection;

  /// No description provided for @profilePreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferencesSection;

  /// No description provided for @profileHelpSupportSection.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupportSection;

  /// No description provided for @profileAboutLegalSection.
  ///
  /// In en, this message translates to:
  /// **'About & Legal'**
  String get profileAboutLegalSection;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get supportCenter;

  /// No description provided for @aboutAmomyApp.
  ///
  /// In en, this message translates to:
  /// **'About AMOMY App'**
  String get aboutAmomyApp;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get chooseFromPhotos;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @avatarUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated successfully'**
  String get avatarUpdatedSuccess;

  /// No description provided for @avatarRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed successfully'**
  String get avatarRemovedSuccess;

  /// No description provided for @avatarUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile photo'**
  String get avatarUpdateFailed;

  /// No description provided for @avatarRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove profile photo'**
  String get avatarRemoveFailed;

  /// No description provided for @supportHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get supportHeroTitle;

  /// No description provided for @supportHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We are here to assist you with your trips, bookings, and account.'**
  String get supportHeroSubtitle;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @faqQuestion1.
  ///
  /// In en, this message translates to:
  /// **'How do I book a seat on a bus?'**
  String get faqQuestion1;

  /// No description provided for @faqAnswer1.
  ///
  /// In en, this message translates to:
  /// **'Choose your departure and destination stops, select your trip time, and pick an available seat directly on the bus map.'**
  String get faqAnswer1;

  /// No description provided for @faqQuestion2.
  ///
  /// In en, this message translates to:
  /// **'How does the Points wallet work?'**
  String get faqQuestion2;

  /// No description provided for @faqAnswer2.
  ///
  /// In en, this message translates to:
  /// **'Your wallet uses points where 1 Point = 1 EGP. You can top up your balance via Vodafone Cash or InstaPay.'**
  String get faqAnswer2;

  /// No description provided for @faqQuestion3.
  ///
  /// In en, this message translates to:
  /// **'How do I board the bus?'**
  String get faqQuestion3;

  /// No description provided for @faqAnswer3.
  ///
  /// In en, this message translates to:
  /// **'Show your digital QR ticket from the app to the driver or staff member when boarding.'**
  String get faqAnswer3;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'AMOMY Bus is a modern passenger transportation app designed for reliable daily commuting in Egypt.'**
  String get aboutAppDescription;

  /// No description provided for @aboutFeature1.
  ///
  /// In en, this message translates to:
  /// **'View scheduled trips and routes'**
  String get aboutFeature1;

  /// No description provided for @aboutFeature2.
  ///
  /// In en, this message translates to:
  /// **'Reserve available seats in real time'**
  String get aboutFeature2;

  /// No description provided for @aboutFeature3.
  ///
  /// In en, this message translates to:
  /// **'Manage your bookings and trip history'**
  String get aboutFeature3;

  /// No description provided for @aboutFeature4.
  ///
  /// In en, this message translates to:
  /// **'Top up and pay with Points wallet'**
  String get aboutFeature4;

  /// No description provided for @aboutFeature5.
  ///
  /// In en, this message translates to:
  /// **'Access digital QR tickets for quick boarding'**
  String get aboutFeature5;

  /// No description provided for @aboutFeature6.
  ///
  /// In en, this message translates to:
  /// **'Receive real-time trip and service notifications'**
  String get aboutFeature6;

  /// No description provided for @aboutFeature7.
  ///
  /// In en, this message translates to:
  /// **'Track supported buses during operating hours'**
  String get aboutFeature7;

  /// No description provided for @developerSection.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developerSection;

  /// No description provided for @developerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developerNameLabel;

  /// No description provided for @developerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get developerEmailLabel;

  /// No description provided for @developerWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get developerWebsiteLabel;

  /// No description provided for @developerLinkedInLabel.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get developerLinkedInLabel;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @privacyPolicyUrl.
  ///
  /// In en, this message translates to:
  /// **'https://amomy.com/privacy-policy'**
  String get privacyPolicyUrl;

  /// No description provided for @termsAndConditionsUrl.
  ///
  /// In en, this message translates to:
  /// **'https://amomy.com/terms-and-conditions'**
  String get termsAndConditionsUrl;

  /// No description provided for @noTripsAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'No trips available today'**
  String get noTripsAvailableToday;

  /// No description provided for @noMoreTripsAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'No more trips available today'**
  String get noMoreTripsAvailableToday;

  /// No description provided for @trackingOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get trackingOffline;

  /// No description provided for @trackingLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get trackingLive;

  /// No description provided for @trackingAssignmentPending.
  ///
  /// In en, this message translates to:
  /// **'Bus assignment pending'**
  String get trackingAssignmentPending;

  /// No description provided for @trackingLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location temporarily unavailable'**
  String get trackingLocationUnavailable;

  /// No description provided for @trackingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tracking unavailable'**
  String get trackingUnavailable;

  /// No description provided for @trackingProgressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stop progress temporarily unavailable'**
  String get trackingProgressUnavailable;

  /// No description provided for @trackingTripNotActive.
  ///
  /// In en, this message translates to:
  /// **'Trip tracking is not active'**
  String get trackingTripNotActive;

  /// No description provided for @trackingLastStop.
  ///
  /// In en, this message translates to:
  /// **'Last Stop'**
  String get trackingLastStop;

  /// No description provided for @trackingReached.
  ///
  /// In en, this message translates to:
  /// **'Reached {time}'**
  String trackingReached(String time);

  /// No description provided for @trackingCurrentStop.
  ///
  /// In en, this message translates to:
  /// **'Current Stop'**
  String get trackingCurrentStop;

  /// No description provided for @trackingNextStop.
  ///
  /// In en, this message translates to:
  /// **'Next Stop'**
  String get trackingNextStop;

  /// No description provided for @trackingEtaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'ETA unavailable'**
  String get trackingEtaUnavailable;

  /// No description provided for @trackingResumesMidday.
  ///
  /// In en, this message translates to:
  /// **'Tracking resumes at 1:00 PM'**
  String get trackingResumesMidday;

  /// No description provided for @trackingResumesTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tracking resumes tomorrow at 8:00 AM'**
  String get trackingResumesTomorrow;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get bookingStatusNoShow;

  /// No description provided for @bookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingStatusPending;

  /// No description provided for @errorHoldExpired.
  ///
  /// In en, this message translates to:
  /// **'Seat hold expired. Please select a seat again.'**
  String get errorHoldExpired;

  /// No description provided for @errorBookingClosed.
  ///
  /// In en, this message translates to:
  /// **'Booking is no longer available for this trip.'**
  String get errorBookingClosed;

  /// No description provided for @errorCancellationWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation period has ended.'**
  String get errorCancellationWindowClosed;

  /// No description provided for @errorChangeSeatWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Seat change period has ended.'**
  String get errorChangeSeatWindowClosed;

  /// No description provided for @errorServiceDayOff.
  ///
  /// In en, this message translates to:
  /// **'No trips available today.'**
  String get errorServiceDayOff;

  /// No description provided for @changeSeat.
  ///
  /// In en, this message translates to:
  /// **'Change Seat'**
  String get changeSeat;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @viewLiveMap.
  ///
  /// In en, this message translates to:
  /// **'View Live Map'**
  String get viewLiveMap;

  /// No description provided for @viewTrip.
  ///
  /// In en, this message translates to:
  /// **'View Trip'**
  String get viewTrip;

  /// No description provided for @extraSeat.
  ///
  /// In en, this message translates to:
  /// **'Extra Seat'**
  String get extraSeat;

  /// No description provided for @addExtraSeat.
  ///
  /// In en, this message translates to:
  /// **'Add Extra Seat'**
  String get addExtraSeat;

  /// No description provided for @digitalBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'Digital Boarding Pass'**
  String get digitalBoardingPass;

  /// No description provided for @accessBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Restricted'**
  String get accessBlockedTitle;

  /// No description provided for @deviceBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This device has been blocked from using AMOMY Bus'**
  String get deviceBlockedMessage;

  /// No description provided for @accountSuspendedMessage.
  ///
  /// In en, this message translates to:
  /// **'This account has been suspended'**
  String get accountSuspendedMessage;

  /// No description provided for @accountSuspendedUntilMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended until {date}'**
  String accountSuspendedUntilMessage(String date);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
