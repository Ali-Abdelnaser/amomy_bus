import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../domain/entities/referral_entities.dart';
import 'referral_qr_dialog.dart';
import '../services/referral_share_service.dart';

class MyReferralsTab extends StatelessWidget {
  final ReferralDashboard dashboard;
  final VoidCallback onRefresh;

  const MyReferralsTab({
    super.key,
    required this.dashboard,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isEnabled = dashboard.program.enabled;
    final stats = dashboard.inviterStats;
    final limit = dashboard.program.monthlyInviteLimit;
    final accepted = stats.acceptedThisMonth;
    final progressFraction = limit > 0 ? (accepted / limit).clamp(0.0, 1.0) : 0.0;
    final friends = dashboard.inviteesThisMonth;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [


          // HERO CODE CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00355F), Color(0xFF02518F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00355F).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'كود الدعوة الخاص بك' : 'YOUR REFERRAL CODE',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.ticket,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAr
                                ? '+${dashboard.program.inviterFirstRewardPoints.toInt()} نقطة لكل صديق'
                                : '+${dashboard.program.inviterFirstRewardPoints.toInt()} pts per friend',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH12,

                // Big Code Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      dashboard.myCode.isNotEmpty
                          ? dashboard.myCode
                          : 'AMY-••••••••',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapH20,

                // Action Buttons: Copy, Share, QR
                Row(
                  children: [
                    // Copy button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isEnabled && dashboard.myCode.isNotEmpty
                            ? () {
                                Clipboard.setData(
                                  ClipboardData(text: dashboard.myCode),
                                );
                                AppSnackBar.showSuccess(
                                  context,
                                  isAr
                                      ? 'تم نسخ الكود: ${dashboard.myCode}'
                                      : 'Code copied: ${dashboard.myCode}',
                                );
                              }
                            : null,
                        icon: const Icon(AppIcons.copy, size: 16),
                        label: Text(isAr ? 'نسخ' : 'Copy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapW8,

                    // Share button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isEnabled && dashboard.myCode.isNotEmpty
                            ? () {
                                final box =
                                    context.findRenderObject() as RenderBox?;
                                final origin = box != null
                                    ? box.localToGlobal(Offset.zero) & box.size
                                    : null;
                                ReferralShareService.shareInvite(
                                  code: dashboard.myCode,
                                  isArabic: isAr,
                                  sharePositionOrigin: origin,
                                );
                              }
                            : null,
                        icon: const Icon(AppIcons.share, size: 16),
                        label: Text(isAr ? 'مشاركة' : 'Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapW8,

                    // QR button
                    Material(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: isEnabled && dashboard.myCode.isNotEmpty
                            ? () => ReferralQrDialog.show(
                                  context,
                                  code: dashboard.myCode,
                                )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            AppIcons.qrCode,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH20,

          // STATS OVERVIEW: Monthly progress & Total rewards
          Row(
            children: [
              // Monthly Progress Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'دعوات هذا الشهر' : 'Monthly Progress',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapH6,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$accepted',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            ' / $limit',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF2F4F7),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressFraction >= 1.0
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapW12,

              // Total Points Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'النقاط المكتسبة' : 'Reward Points',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapH6,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${stats.totalRewardPointsEarned.toInt()}',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF027A48),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? 'نقطة' : 'pts',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      Text(
                        isAr
                            ? 'إجمالي ${stats.totalInvited} صديق منضم'
                            : '${stats.totalInvited} total friends joined',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH24,

          // SECTION TITLE: Friends List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'الأصدقاء المدعوون هذا الشهر' : 'Friends Invited This Month',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${friends.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,

          // FRIENDS LIST or EMPTY STATE
          if (friends.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF2F4F7),
                    ),
                    child: const Icon(
                      AppIcons.userPlus,
                      color: AppColors.textTertiary,
                      size: 26,
                    ),
                  ),
                  AppSpacing.gapH14,
                  Text(
                    isAr
                        ? 'لم تقم بدعوة أي أصدقاء هذا الشهر بعد'
                        : 'No friends invited this month yet',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH6,
                  Text(
                    isAr
                        ? 'شارك كود الدعوة الخاص بك واكسب نقاطاً فور إتمام أول رحلة لهم!'
                        : 'Share your code and earn points as soon as they complete their first trip!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...friends.map((friend) => _buildFriendCard(context, friend, isAr)),
        ],
      ),
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    InvitedFriendItem friend,
    bool isAr,
  ) {
    final milestoneTotal = friend.milestoneTripCount > 0
        ? friend.milestoneTripCount
        : 3;
    final tripProgress = friend.qualifiedTripCount.clamp(0, milestoneTotal);
    final dateStr = DateFormat.MMMd(isAr ? 'ar' : 'en').format(friend.acceptedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: friend.inviteeAvatarUrl != null
                    ? NetworkImage(friend.inviteeAvatarUrl!)
                    : null,
                child: friend.inviteeAvatarUrl == null
                    ? Text(
                        friend.inviteeName.isNotEmpty
                            ? friend.inviteeName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              AppSpacing.gapW12,

              // Name & Accepted Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.inviteeName,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isAr ? 'انضم في $dateStr' : 'Joined on $dateStr',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress badge X / 3
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tripProgress >= milestoneTotal
                      ? const Color(0xFFECFDF3)
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAr
                      ? '$tripProgress من $milestoneTotal رحلات'
                      : '$tripProgress / $milestoneTotal trips',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tripProgress >= milestoneTotal
                        ? const Color(0xFF027A48)
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,

          // Trip progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tripProgress / milestoneTotal,
              minHeight: 5,
              backgroundColor: const Color(0xFFF2F4F7),
              valueColor: AlwaysStoppedAnimation<Color>(
                tripProgress >= milestoneTotal
                    ? const Color(0xFF12B76A)
                    : AppColors.primary,
              ),
            ),
          ),
          AppSpacing.gapH10,

          // Rewards chips row
          Row(
            children: [
              _buildRewardChip(
                isAr
                    ? 'أول رحلة (+${friend.firstRewardPoints.toInt()})'
                    : '1st Trip (+${friend.firstRewardPoints.toInt()})',
                friend.firstRewardGranted,
                isAr,
              ),
              const SizedBox(width: 8),
              _buildRewardChip(
                isAr
                    ? 'الهدف (+${friend.milestoneRewardPoints.toInt()})'
                    : 'Milestone (+${friend.milestoneRewardPoints.toInt()})',
                friend.milestoneRewardGranted,
                isAr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(String label, bool isGranted, bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isGranted ? const Color(0xFFECFDF3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isGranted ? const Color(0xFFA6F4C5) : const Color(0xFFE4E7EC),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? AppIcons.checkCircle : AppIcons.clock,
            size: 12,
            color: isGranted ? const Color(0xFF027A48) : AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10.5,
              fontWeight: isGranted ? FontWeight.w700 : FontWeight.w500,
              color: isGranted
                  ? const Color(0xFF027A48)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
