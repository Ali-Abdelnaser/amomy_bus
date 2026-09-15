class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String designSystemPreview = '/design-system';

  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/verify-email';
  static const String completeProfile = '/complete-profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String trips = '/trips';
  static const String bookTrip = '/book-trip';
  static const String tripDetails = '/trips/:tripId';
  static const String seatSelection = '/trips/:tripId/seats';
  static const String bookingConfirmation = '/booking/confirmation';
  static const String myBookings = '/my-bookings';
  static const String bookingQr = '/bookings/:bookingId/qr';
  static const String wallet = '/wallet';
  static const String addPoints = '/add-points';
  static const String changeSeat = '/change-seat';
  static const String subscriptions = '/subscriptions';
  static const String profile = '/profile';
  static const String personalInformation = '/personal-information';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notification-settings';
  static const String support = '/support';
  static const String aboutApp = '/about-app';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String liveTracking = '/trips/:tripId/tracking';
  static const String liveBusMap = '/live-map';

  // Admin paths
  static const String admin = '/admin';
  static const String adminRechargeApprovals = '/admin/recharges';
  static const String adminTripManagement = '/admin/trips';
  static const String adminAuditLogs = '/admin/audit-logs';
}
