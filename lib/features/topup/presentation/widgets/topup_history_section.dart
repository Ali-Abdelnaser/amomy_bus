import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/topup_entities.dart';

class TopUpHistorySection extends StatelessWidget {
  final List<TopUpRequest> requests;
  final bool isLoading;

  const TopUpHistorySection({
    super.key,
    required this.requests,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final formatter = NumberFormat('#,###');
    final dateFormat = DateFormat.yMMMd(isArabic ? 'ar' : 'en').add_jm();

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(AppIcons.clock, size: 32, color: AppColors.textTertiary),
              AppSpacing.gapH8,
              Text(
                l10n.topUpEmptyHistory,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: requests.map((req) {
        final (statusText, statusColor, statusBg) = switch (req.status) {
          TopUpStatus.pending => (
              l10n.topUpStatusPending,
              AppColors.warning,
              AppColors.warningLight.withValues(alpha: 0.4),
            ),
          TopUpStatus.approved => (
              l10n.topUpStatusApproved,
              AppColors.success,
              AppColors.successLight.withValues(alpha: 0.4),
            ),
          TopUpStatus.rejected => (
              l10n.topUpStatusRejected,
              AppColors.error,
              AppColors.errorLight.withValues(alpha: 0.4),
            ),
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${formatter.format(req.requestedAmount)} EGP',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH8,
                Row(
                  children: [
                    const Icon(AppIcons.wallet, size: 14, color: AppColors.textSecondary),
                    AppSpacing.gapW4,
                    Text(
                      req.getLocalizedMethodName(isArabic),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    if (req.paymentReference != null && req.paymentReference!.isNotEmpty) ...[
                      AppSpacing.gapW8,
                      const Text('•', style: TextStyle(color: AppColors.textTertiary)),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          req.paymentReference!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateFormat.format(req.createdAt.toLocal()),
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
                if (req.status == TopUpStatus.rejected &&
                    req.rejectionReason != null &&
                    req.rejectionReason!.isNotEmpty) ...[
                  AppSpacing.gapH8,
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(AppIcons.info, size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${l10n.topUpRejectionReason}: ${req.rejectionReason}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
