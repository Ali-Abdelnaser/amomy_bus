import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
    final isArabic = Localizations.localeOf(context).languageCode.startsWith('ar');
    final formatter = NumberFormat('#,###');
    final dateFormat = DateFormat.yMMMd(isArabic ? 'ar' : 'en').add_jm();

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
          TopUpStatus.awaitingPayment => (
              l10n.statusAwaitingPayment,
              const Color(0xFF475467),
              const Color(0xFFF2F4F7),
            ),
          TopUpStatus.pending => (
              l10n.statusPendingReview,
              const Color(0xFFB54708),
              const Color(0xFFFEF0C7),
            ),
          TopUpStatus.approved => (
              l10n.statusApproved,
              const Color(0xFF027A48),
              const Color(0xFFECFDF3),
            ),
          TopUpStatus.rejected => (
              l10n.statusRejected,
              const Color(0xFFB42318),
              const Color(0xFFFEE4E2),
            ),
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${formatter.format(req.requestedAmount)} ${l10n.ptsUnit}',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
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
                        style: TextStyle(
                          fontSize: 11.5,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH8,
                Row(
                  children: [
                    const Icon(AppIcons.wallet, size: 14, color: AppColors.textSecondary),
                    AppSpacing.gapW6,
                    Text(
                      'EGP ${formatter.format(req.expectedAmountEgp.round())}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (req.publicId != null && req.publicId!.isNotEmpty) ...[
                      AppSpacing.gapW8,
                      const Text('•', style: TextStyle(color: AppColors.textTertiary)),
                      AppSpacing.gapW8,
                      Text(
                        req.publicId!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateFormat.format(req.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
                if (req.status == TopUpStatus.rejected &&
                    req.rejectionReason != null &&
                    req.rejectionReason!.isNotEmpty) ...[
                  AppSpacing.gapH8,
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE4E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(AppIcons.info, size: 14, color: Color(0xFFB42318)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${l10n.topUpRejectionReason}: ${req.rejectionReason}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB42318),
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
