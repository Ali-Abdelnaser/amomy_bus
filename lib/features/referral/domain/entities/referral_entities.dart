import 'package:equatable/equatable.dart';

/// Configuration settings for the referral system.
class ReferralProgramSettings extends Equatable {
  final bool enabled;
  final double inviterFirstRewardPoints;
  final double inviteeFirstRewardPoints;
  final int milestoneTripCount;
  final double inviterMilestoneRewardPoints;
  final int monthlyInviteLimit;

  const ReferralProgramSettings({
    required this.enabled,
    required this.inviterFirstRewardPoints,
    required this.inviteeFirstRewardPoints,
    required this.milestoneTripCount,
    required this.inviterMilestoneRewardPoints,
    required this.monthlyInviteLimit,
  });

  @override
  List<Object?> get props => [
    enabled,
    inviterFirstRewardPoints,
    inviteeFirstRewardPoints,
    milestoneTripCount,
    inviterMilestoneRewardPoints,
    monthlyInviteLimit,
  ];
}

/// Aggregated stats for the user as an inviter.
class InviterStats extends Equatable {
  final int acceptedThisMonth;
  final int remainingThisMonth;
  final int totalInvited;
  final double totalRewardPointsEarned;

  const InviterStats({
    required this.acceptedThisMonth,
    required this.remainingThisMonth,
    required this.totalInvited,
    required this.totalRewardPointsEarned,
  });

  @override
  List<Object?> get props => [
    acceptedThisMonth,
    remainingThisMonth,
    totalInvited,
    totalRewardPointsEarned,
  ];
}

/// Information about who invited the current passenger.
class InvitedByInfo extends Equatable {
  final String referralId;
  final String inviterUserId;
  final String inviterName;
  final String? inviterAvatarUrl;
  final DateTime acceptedAt;
  final String source;

  const InvitedByInfo({
    required this.referralId,
    required this.inviterUserId,
    required this.inviterName,
    this.inviterAvatarUrl,
    required this.acceptedAt,
    required this.source,
  });

  @override
  List<Object?> get props => [
    referralId,
    inviterUserId,
    inviterName,
    inviterAvatarUrl,
    acceptedAt,
    source,
  ];
}

/// The current passenger's progress toward earning referral rewards from their inviter.
class InviteeProgress extends Equatable {
  final String referralId;
  final int qualifiedTripCount;
  final int milestoneTripCount;
  final double firstTripRewardPoints;
  final bool firstTripRewardGranted;
  final String status;

  const InviteeProgress({
    required this.referralId,
    required this.qualifiedTripCount,
    required this.milestoneTripCount,
    required this.firstTripRewardPoints,
    required this.firstTripRewardGranted,
    required this.status,
  });

  @override
  List<Object?> get props => [
    referralId,
    qualifiedTripCount,
    milestoneTripCount,
    firstTripRewardPoints,
    firstTripRewardGranted,
    status,
  ];
}

/// An invited friend row in the current passenger's dashboard.
class InvitedFriendItem extends Equatable {
  final String referralId;
  final String inviteeUserId;
  final String inviteeName;
  final String? inviteeAvatarUrl;
  final DateTime acceptedAt;
  final String source;
  final String status;
  final int qualifiedTripCount;
  final int milestoneTripCount;
  final double firstRewardPoints;
  final bool firstRewardGranted;
  final double milestoneRewardPoints;
  final bool milestoneRewardGranted;

  const InvitedFriendItem({
    required this.referralId,
    required this.inviteeUserId,
    required this.inviteeName,
    this.inviteeAvatarUrl,
    required this.acceptedAt,
    required this.source,
    required this.status,
    required this.qualifiedTripCount,
    required this.milestoneTripCount,
    required this.firstRewardPoints,
    required this.firstRewardGranted,
    required this.milestoneRewardPoints,
    required this.milestoneRewardGranted,
  });

  @override
  List<Object?> get props => [
    referralId,
    inviteeUserId,
    inviteeName,
    inviteeAvatarUrl,
    acceptedAt,
    source,
    status,
    qualifiedTripCount,
    milestoneTripCount,
    firstRewardPoints,
    firstRewardGranted,
    milestoneRewardPoints,
    milestoneRewardGranted,
  ];
}

/// Comprehensive referral dashboard entity returned by `get_my_referral_dashboard`.
class ReferralDashboard extends Equatable {
  final ReferralProgramSettings program;
  final String myCode;
  final InviterStats inviterStats;
  final InvitedByInfo? invitedBy;
  final InviteeProgress? inviteeProgress;
  final List<InvitedFriendItem> inviteesThisMonth;

  const ReferralDashboard({
    required this.program,
    required this.myCode,
    required this.inviterStats,
    this.invitedBy,
    this.inviteeProgress,
    this.inviteesThisMonth = const [],
  });

  bool get isLinked => invitedBy != null;

  @override
  List<Object?> get props => [
    program,
    myCode,
    inviterStats,
    invitedBy,
    inviteeProgress,
    inviteesThisMonth,
  ];
}

/// Preview details of a referral code before the user confirms binding.
class ReferralCodePreview extends Equatable {
  final bool valid;
  final bool programEnabled;
  final String? code;
  final String? inviterUserId;
  final String? inviterName;
  final String? inviterAvatarUrl;
  final double? inviteeFirstRewardPoints;
  final double? inviterFirstRewardPoints;
  final int? milestoneTripCount;
  final double? inviterMilestoneRewardPoints;
  final String? reason;

  const ReferralCodePreview({
    required this.valid,
    required this.programEnabled,
    this.code,
    this.inviterUserId,
    this.inviterName,
    this.inviterAvatarUrl,
    this.inviteeFirstRewardPoints,
    this.inviterFirstRewardPoints,
    this.milestoneTripCount,
    this.inviterMilestoneRewardPoints,
    this.reason,
  });

  String localizedError({required bool isArabic}) {
    if (reason == null) {
      return isArabic ? 'كود الدعوة غير صالح' : 'Invalid referral code';
    }
    switch (reason) {
      case 'PROGRAM_DISABLED':
        return isArabic
            ? 'برنامج الدعوات متوقف حالياً'
            : 'The referral program is currently disabled';
      case 'INVALID_CODE':
        return isArabic
            ? 'كود الدعوة غير موجود أو غير نشط'
            : 'Invalid or inactive referral code';
      case 'SELF_INVITE':
        return isArabic
            ? 'لا يمكنك استخدام كود الدعوة الخاص بك'
            : 'You cannot use your own referral code';
      case 'ALREADY_REFERRED':
        return isArabic
            ? 'حسابك مربوط بالفعل بكود دعوة مسبقاً'
            : 'Your account is already linked to a referral code';
      case 'NOT_ELIGIBLE_ALREADY_TRAVELLED':
        return isArabic
            ? 'أكواد الدعوة متاحة فقط للركاب الجدد قبل إتمام رحلتهم الأولى'
            : 'Referral codes are only eligible for new passengers before their first completed trip';
      case 'INVITER_UNAVAILABLE':
        return isArabic
            ? 'صاحب كود الدعوة غير متاح حالياً'
            : 'Inviter account is currently unavailable';
      case 'MONTHLY_LIMIT_REACHED':
        return isArabic
            ? 'وصل صاحب الدعوة للحد الأقصى للدعوات هذا الشهر'
            : 'The inviter has reached their monthly invite limit';
      default:
        return isArabic ? 'تعذر التحقق من كود الدعوة' : 'Unable to verify referral code';
    }
  }

  @override
  List<Object?> get props => [
    valid,
    programEnabled,
    code,
    inviterUserId,
    inviterName,
    inviterAvatarUrl,
    inviteeFirstRewardPoints,
    inviterFirstRewardPoints,
    milestoneTripCount,
    inviterMilestoneRewardPoints,
    reason,
  ];
}

/// Result of binding a referral code.
class BindReferralResult extends Equatable {
  final bool success;
  final String referralId;
  final String inviterUserId;
  final String inviterName;
  final double inviteeFirstRewardPoints;
  final int milestoneTripCount;

  const BindReferralResult({
    required this.success,
    required this.referralId,
    required this.inviterUserId,
    required this.inviterName,
    required this.inviteeFirstRewardPoints,
    required this.milestoneTripCount,
  });

  @override
  List<Object?> get props => [
    success,
    referralId,
    inviterUserId,
    inviterName,
    inviteeFirstRewardPoints,
    milestoneTripCount,
  ];
}
