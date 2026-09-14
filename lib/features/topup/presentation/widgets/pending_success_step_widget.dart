import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class PendingSuccessStepWidget extends StatelessWidget {
  final int points;
  final double amountEgp;
  final String? publicId;
  final bool isResubmit;
  final VoidCallback onReturnToWallet;

  const PendingSuccessStepWidget({
    super.key,
    required this.points,
    required this.amountEgp,
    this.publicId,
    this.isResubmit = false,
    required this.onReturnToWallet,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),

        // 1. Pending clock / hourglass icon
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 40,
              color: Color(0xFFD97706),
            ),
          ),
        ),
        AppSpacing.gapH24,

        // 2. Title & Subtitle
        Text(
          isResubmit ? l10n.paymentResubmittedTitle : l10n.paymentSubmittedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        AppSpacing.gapH8,
        Text(
          l10n.paymentUnderReviewSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        AppSpacing.gapH24,

        // 3. Details Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildRow(
                context,
                label: l10n.actionAddPoints,
                value: '${formatter.format(points)} ${l10n.ptsUnit}',
                isBold: true,
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildRow(
                context,
                label: l10n.transferAmount,
                value: 'EGP ${formatter.format(amountEgp.round())}',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildRow(
                context,
                label: Localizations.localeOf(context).languageCode == 'ar' ? 'الحالة' : 'Status',
                badgeText: l10n.statusPendingReview,
                badgeBg: const Color(0xFFFEF3C7),
                badgeFg: const Color(0xFFB45309),
              ),
              if (publicId != null && publicId!.isNotEmpty) ...[
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRow(
                  context,
                  label: l10n.requestIdLabel,
                  value: publicId!,
                  isMonospace: true,
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        // 4. CTA: Back to Wallet
        AppButton(
          label: l10n.backToWalletCta,
          onPressed: onReturnToWallet,
          isFullWidth: true,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    String? value,
    bool isBold = false,
    bool isMonospace = false,
    String? badgeText,
    Color? badgeBg,
    Color? badgeFg,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg ?? const Color(0xFFEFF6FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeFg ?? AppColors.primary,
              ),
            ),
          )
        else if (value != null)
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontFamily: isMonospace ? 'monospace' : null,
              color: AppColors.textPrimary,
              letterSpacing: isMonospace ? 0.8 : null,
            ),
          ),
      ],
    );
  }
}
