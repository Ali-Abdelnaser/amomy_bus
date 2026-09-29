import '../../domain/entities/referral_entities.dart';

class ReferralProgramSettingsModel extends ReferralProgramSettings {
  const ReferralProgramSettingsModel({
    required super.enabled,
    required super.inviterFirstRewardPoints,
    required super.inviteeFirstRewardPoints,
    required super.milestoneTripCount,
    required super.inviterMilestoneRewardPoints,
    required super.monthlyInviteLimit,
  });

  factory ReferralProgramSettingsModel.fromJson(Map<String, dynamic> json) {
    return ReferralProgramSettingsModel(
      enabled: json['enabled'] as bool? ?? false,
      inviterFirstRewardPoints:
          (json['inviter_first_reward_points'] as num?)?.toDouble() ?? 5.0,
      inviteeFirstRewardPoints:
          (json['invitee_first_reward_points'] as num?)?.toDouble() ?? 5.0,
      milestoneTripCount: (json['milestone_trip_count'] as num?)?.toInt() ?? 3,
      inviterMilestoneRewardPoints:
          (json['inviter_milestone_reward_points'] as num?)?.toDouble() ?? 10.0,
      monthlyInviteLimit:
          (json['monthly_invite_limit'] as num?)?.toInt() ?? 5,
    );
  }
}

class InviterStatsModel extends InviterStats {
  const InviterStatsModel({
    required super.acceptedThisMonth,
    required super.remainingThisMonth,
    required super.totalInvited,
    required super.totalRewardPointsEarned,
  });

  factory InviterStatsModel.fromJson(Map<String, dynamic> json) {
    return InviterStatsModel(
      acceptedThisMonth: (json['accepted_this_month'] as num?)?.toInt() ?? 0,
      remainingThisMonth: (json['remaining_this_month'] as num?)?.toInt() ?? 0,
      totalInvited: (json['total_invited'] as num?)?.toInt() ?? 0,
      totalRewardPointsEarned:
          (json['total_reward_points_earned'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvitedByInfoModel extends InvitedByInfo {
  const InvitedByInfoModel({
    required super.referralId,
    required super.inviterUserId,
    required super.inviterName,
    super.inviterAvatarUrl,
    required super.acceptedAt,
    required super.source,
  });

  factory InvitedByInfoModel.fromJson(Map<String, dynamic> json) {
    return InvitedByInfoModel(
      referralId: json['referral_id'] as String? ?? '',
      inviterUserId: json['inviter_user_id'] as String? ?? '',
      inviterName: json['inviter_name'] as String? ?? '',
      inviterAvatarUrl: json['inviter_avatar_url'] as String?,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] as String? ?? 'manual_code',
    );
  }
}

class InviteeProgressModel extends InviteeProgress {
  const InviteeProgressModel({
    required super.referralId,
    required super.qualifiedTripCount,
    required super.milestoneTripCount,
    required super.firstTripRewardPoints,
    required super.firstTripRewardGranted,
    required super.status,
  });

  factory InviteeProgressModel.fromJson(Map<String, dynamic> json) {
    return InviteeProgressModel(
      referralId: json['referral_id'] as String? ?? '',
      qualifiedTripCount: (json['qualified_trip_count'] as num?)?.toInt() ?? 0,
      milestoneTripCount: (json['milestone_trip_count'] as num?)?.toInt() ?? 3,
      firstTripRewardPoints:
          (json['first_trip_reward_points'] as num?)?.toDouble() ?? 5.0,
      firstTripRewardGranted:
          json['first_trip_reward_granted'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class InvitedFriendItemModel extends InvitedFriendItem {
  const InvitedFriendItemModel({
    required super.referralId,
    required super.inviteeUserId,
    required super.inviteeName,
    super.inviteeAvatarUrl,
    required super.acceptedAt,
    required super.source,
    required super.status,
    required super.qualifiedTripCount,
    required super.milestoneTripCount,
    required super.firstRewardPoints,
    required super.firstRewardGranted,
    required super.milestoneRewardPoints,
    required super.milestoneRewardGranted,
  });

  factory InvitedFriendItemModel.fromJson(Map<String, dynamic> json) {
    return InvitedFriendItemModel(
      referralId: json['referral_id'] as String? ?? '',
      inviteeUserId: json['invitee_user_id'] as String? ?? '',
      inviteeName: json['invitee_name'] as String? ?? '',
      inviteeAvatarUrl: json['invitee_avatar_url'] as String?,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] as String? ?? 'manual_code',
      status: json['status'] as String? ?? 'active',
      qualifiedTripCount: (json['qualified_trip_count'] as num?)?.toInt() ?? 0,
      milestoneTripCount: (json['milestone_trip_count'] as num?)?.toInt() ?? 3,
      firstRewardPoints:
          (json['first_reward_points'] as num?)?.toDouble() ?? 5.0,
      firstRewardGranted: json['first_reward_granted'] as bool? ?? false,
      milestoneRewardPoints:
          (json['milestone_reward_points'] as num?)?.toDouble() ?? 10.0,
      milestoneRewardGranted:
          json['milestone_reward_granted'] as bool? ?? false,
    );
  }
}

class ReferralDashboardModel extends ReferralDashboard {
  const ReferralDashboardModel({
    required super.program,
    required super.myCode,
    required super.inviterStats,
    super.invitedBy,
    super.inviteeProgress,
    super.inviteesThisMonth,
  });

  factory ReferralDashboardModel.fromJson(Map<String, dynamic> json) {
    final progJson = json['program'] as Map<String, dynamic>? ?? {};
    final statsJson = json['inviter_stats'] as Map<String, dynamic>? ?? {};
    final invitedByJson = json['invited_by'] as Map<String, dynamic>?;
    final progressJson = json['invitee_progress'] as Map<String, dynamic>?;
    final inviteesRaw = json['invitees_this_month'] as List<dynamic>? ?? [];

    return ReferralDashboardModel(
      program: ReferralProgramSettingsModel.fromJson(progJson),
      myCode: json['my_code'] as String? ?? '',
      inviterStats: InviterStatsModel.fromJson(statsJson),
      invitedBy: invitedByJson != null
          ? InvitedByInfoModel.fromJson(invitedByJson)
          : null,
      inviteeProgress: progressJson != null
          ? InviteeProgressModel.fromJson(progressJson)
          : null,
      inviteesThisMonth: inviteesRaw
          .whereType<Map<String, dynamic>>()
          .map((item) => InvitedFriendItemModel.fromJson(item))
          .toList(),
    );
  }
}

class ReferralCodePreviewModel extends ReferralCodePreview {
  const ReferralCodePreviewModel({
    required super.valid,
    required super.programEnabled,
    super.code,
    super.inviterUserId,
    super.inviterName,
    super.inviterAvatarUrl,
    super.inviteeFirstRewardPoints,
    super.inviterFirstRewardPoints,
    super.milestoneTripCount,
    super.inviterMilestoneRewardPoints,
    super.reason,
  });

  factory ReferralCodePreviewModel.fromJson(Map<String, dynamic> json) {
    return ReferralCodePreviewModel(
      valid: json['valid'] as bool? ?? false,
      programEnabled: json['program_enabled'] as bool? ?? true,
      code: json['code'] as String?,
      inviterUserId: json['inviter_user_id'] as String?,
      inviterName: json['inviter_name'] as String?,
      inviterAvatarUrl: json['inviter_avatar_url'] as String?,
      inviteeFirstRewardPoints:
          (json['invitee_first_reward_points'] as num?)?.toDouble(),
      inviterFirstRewardPoints:
          (json['inviter_first_reward_points'] as num?)?.toDouble(),
      milestoneTripCount: (json['milestone_trip_count'] as num?)?.toInt(),
      inviterMilestoneRewardPoints:
          (json['inviter_milestone_reward_points'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
    );
  }
}

class BindReferralResultModel extends BindReferralResult {
  const BindReferralResultModel({
    required super.success,
    required super.referralId,
    required super.inviterUserId,
    required super.inviterName,
    required super.inviteeFirstRewardPoints,
    required super.milestoneTripCount,
  });

  factory BindReferralResultModel.fromJson(Map<String, dynamic> json) {
    return BindReferralResultModel(
      success: json['success'] as bool? ?? true,
      referralId: json['referral_id'] as String? ?? '',
      inviterUserId: json['inviter_user_id'] as String? ?? '',
      inviterName: json['inviter_name'] as String? ?? '',
      inviteeFirstRewardPoints:
          (json['invitee_first_reward_points'] as num?)?.toDouble() ?? 5.0,
      milestoneTripCount: (json['milestone_trip_count'] as num?)?.toInt() ?? 3,
    );
  }
}
