import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/topup_entities.dart';

class ReviewStepWidget extends StatelessWidget {
  final int amount;
  final PaymentMethod method;
  final String reference;
  final List<int> proofBytes;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const ReviewStepWidget({
    super.key,
    required this.amount,
    required this.method,
    required this.reference,
    required this.proofBytes,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = NumberFormat('#,###');
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.topUpReviewTitle,
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapH16,

          // Summary Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow(
                  label: l10n.topUpAmountTitle,
                  value: '${formatter.format(amount)} EGP',
                  isBold: true,
                ),
                const Divider(height: 20),
                _buildRow(
                  label: l10n.topUpExpectedPoints,
                  value: '${formatter.format(amount)} ${l10n.pointsUnit}',
                  valueColor: AppColors.success,
                  isBold: true,
                ),
                const Divider(height: 20),
                _buildRow(
                  label: l10n.topUpSelectMethod,
                  value: method.localizedName(isArabic),
                ),
                const Divider(height: 20),
                _buildRow(
                  label: l10n.topUpTransactionReference,
                  value: reference,
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.topUpPaymentProof,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        Uint8List.fromList(proofBytes),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH16,

          // Manual Review Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(AppIcons.info, size: 18, color: AppColors.primary),
                AppSpacing.gapW8,
                Expanded(
                  child: Text(
                    l10n.topUpManualNotice,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapH24,

          // Bottom Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: AppButton(
                  label: l10n.backAction,
                  variant: AppButtonVariant.outline,
                  onPressed: isSubmitting ? null : onBack,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                flex: 2,
                child: AppButton(
                  label: isSubmitting ? l10n.topUpSubmitting : l10n.topUpSubmitButton,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : onSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
