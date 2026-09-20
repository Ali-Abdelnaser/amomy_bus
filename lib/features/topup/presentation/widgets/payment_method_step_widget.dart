import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/topup_entities.dart';

class PaymentMethodStepWidget extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PaymentMethodStepWidget({
    super.key,
    required this.methods,
    required this.selectedMethod,
    required this.onMethodSelected,
    required this.onNext,
    required this.onBack,
  });

  void _copyIdentifier(BuildContext context, String identifier) {
    Clipboard.setData(ClipboardData(text: identifier));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.topUpCopiedToast),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          l10n.topUpSelectMethod,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapH16,

        // Payment Methods List
        ...methods.map((method) {
          final isSelected = selectedMethod?.id == method.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onMethodSelected(method),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.3)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.wallet,
                        size: 20,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.localizedName(isArabic),
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method.accountIdentifier,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 6 : 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        if (selectedMethod != null) ...[
          AppSpacing.gapH12,
          // Account Identifier & Copy Box
          AppCard(
            backgroundColor: AppColors.surfaceSoft,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.topUpRecipientAccount,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    InkWell(
                      onTap: () => _copyIdentifier(
                        context,
                        selectedMethod!.accountIdentifier,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.info,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            AppSpacing.gapW4,
                            Text(
                              l10n.topUpCopyAccount,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH8,
                SelectableText(
                  selectedMethod!.accountIdentifier,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.primaryDark,
                  ),
                ),
                AppSpacing.gapH12,
                const Divider(height: 1),
                AppSpacing.gapH12,
                Text(
                  l10n.topUpInstructions,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedMethod!.localizedInstructions(isArabic),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Bottom CTA buttons (Back + Continue)
        Row(
          children: [
            Expanded(
              flex: 1,
              child: AppButton(
                label: l10n.backAction,
                variant: AppButtonVariant.outline,
                onPressed: onBack,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              flex: 2,
              child: AppButton(
                label: l10n.continueAction,
                onPressed: selectedMethod != null ? onNext : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
