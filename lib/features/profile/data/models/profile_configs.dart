/// Centralized placeholder configurations for Amomy Passenger Profile.
///
/// NOTE FOR DEVELOPER / MAINTAINER:
/// Update the contact information in [SupportContactData] and
/// developer information in [DeveloperInfoData] before public production release.
class SupportContactData {
  final String supportEmail;
  final String supportPhone;
  final String whatsAppNumber;
  final String workingHoursEn;
  final String workingHoursAr;

  const SupportContactData({
    this.supportEmail = 'alinaserhema60@gmail.com',
    this.supportPhone = '201068643407',
    this.whatsAppNumber = '201068643407',
    this.workingHoursEn = '24/7 Daily Support',
    this.workingHoursAr = 'دعم متواصل على مدار الساعة طوال أيام الأسبوع',
  });
}

class DeveloperInfoData {
  final String developerName;
  final String developerEmail;
  final String developerWebsite;
  final String developerLinkedIn;

  const DeveloperInfoData({
    this.developerName = 'Ali Abdelnaser',
    this.developerEmail = 'alinaserhema60@gmail.com',
    this.developerWebsite =
        'https://portfolio-lp91a6vl1-ali-abdelnasers-projects.vercel.app/',
    this.developerLinkedIn =
        'https://www.linkedin.com/in/ali-abdelnaser-947230295/',
  });
}

/// Single documented access point for profile and app placeholders.
abstract final class ProfilePlaceholderConfig {
  static const SupportContactData support = SupportContactData();
  static const DeveloperInfoData developer = DeveloperInfoData();
}
