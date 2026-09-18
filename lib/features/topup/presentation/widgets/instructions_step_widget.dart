import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/assets/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/topup_entities.dart';

class InstructionsStepWidget extends StatelessWidget {
  final int points;
  final double amountEgp;
  final String receivingPhone;
  final String? methodName;
  final List<PaymentMethod> paymentMethods;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod>? onMethodSelected;
  final bool isSubmitting;
  final VoidCallback onTransferred;
  final VoidCallback onBack;

  const InstructionsStepWidget({
    super.key,
    required this.points,
    required this.amountEgp,
    required this.receivingPhone,
    this.methodName,
    this.paymentMethods = const [],
    this.selectedMethod,
    this.onMethodSelected,
    required this.isSubmitting,
    required this.onTransferred,
    required this.onBack,
  });

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getLogoAsset(String code) {
    if (code.toUpperCase().contains('INSTAPAY')) {
      return AppAssets.instapayLogo;
    }
    return AppAssets.vodafoneCashLogo;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final formatter = NumberFormat('#,###');

    // Default methods if empty
    final methods = paymentMethods.isNotEmpty
        ? paymentMethods
        : [
            PaymentMethod(
              id: 'v_cash',
              code: 'VODAFONE_CASH',
              nameAr: 'فودافون كاش',
              nameEn: 'Vodafone Cash',
              accountIdentifier: receivingPhone,
              instructionsAr: 'قم بتحويل المبلغ إلى رقم فودافون كاش أعلاه.',
              instructionsEn: 'Transfer to the Vodafone Cash number above.',
              iconKey: 'vodafone_cash',
              isActive: true,
              sortOrder: 1,
            ),
            PaymentMethod(
              id: 'i_pay',
              code: 'INSTAPAY',
              nameAr: 'إنستاباي',
              nameEn: 'InstaPay',
              accountIdentifier: receivingPhone,
              instructionsAr:
                  'قم بالتحويل عبر تطبيق إنستاباي إلى الحساب أو العنوان أعلاه.',
              instructionsEn:
                  'Transfer via InstaPay to the account or address above.',
              iconKey: 'instapay',
              isActive: true,
              sortOrder: 2,
            ),
          ];

    final currentSelected =
        selectedMethod ?? (methods.isNotEmpty ? methods.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Amount Summary Banner (fully visible, well-spaced from stepper)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.transferAmount,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            'EGP ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            formatter.format(amountEgp.round()),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${formatter.format(points)} ${l10n.ptsUnit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH14,

                // 2. Payment Method Selector Header
                Text(
                  l10n.choosePaymentMethod,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapH8,

                // Compact Selectable Cards: [ Phone Cash ] & [ InstaPay ]
                ...methods.map((method) {
                  final isChosen =
                      currentSelected != null &&
                      method.code == currentSelected.code;
                  final logoPath = _getLogoAsset(method.code);
                  final displayName = method.localizedName(isAr);
                  final isInsta = method.code.contains('INSTAPAY');
                  final subtitle = isInsta
                      ? (isAr ? 'تحويل بنكي لحظي' : 'Instant transfer')
                      : (isAr ? 'محفظة إلكترونية' : 'Mobile wallet');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => onMethodSelected?.call(method),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isChosen
                              ? const Color(0xFFEFF6FC)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isChosen
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                            width: isChosen ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            _ProviderLogoWidget(
                              assetPath: logoPath,
                              isSelected: isChosen,
                            ),
                            AppSpacing.gapW12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isChosen
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isChosen
                                          ? AppColors.primaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isChosen)
                              const Icon(
                                Icons.radio_button_checked_rounded,
                                size: 20,
                                color: AppColors.primary,
                              )
                            else
                              const Icon(
                                Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: Color(0xFFCBD5E1),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                AppSpacing.gapH4,

                // 3. Conditional Details (AnimatedSwitcher transition when method changes)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: currentSelected != null
                      ? _PaymentDetailsCard(
                          key: ValueKey(currentSelected.code),
                          method: currentSelected,
                          receivingPhone: receivingPhone,
                          logoAsset: _getLogoAsset(currentSelected.code),
                          isAr: isAr,
                          onCopy: (value, msg) =>
                              _copyToClipboard(context, value, msg),
                        )
                      : const SizedBox.shrink(key: ValueKey('none_selected')),
                ),
                AppSpacing.gapH12,
              ],
            ),
          ),
        ),

        // 4. Sticky CTA: I've Made the Transfer (enabled only when method is selected)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppButton(
            label: l10n.iveTransferredCta,
            isLoading: isSubmitting,
            onPressed: (isSubmitting || currentSelected == null)
                ? null
                : onTransferred,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}

/// Reusable compact payment-details card showing selected provider info, receiver number, copy CTA, and 3 clean steps.
class _PaymentDetailsCard extends StatelessWidget {
  final PaymentMethod method;
  final String receivingPhone;
  final String logoAsset;
  final bool isAr;
  final void Function(String text, String message) onCopy;

  const _PaymentDetailsCard({
    super.key,
    required this.method,
    required this.receivingPhone,
    required this.logoAsset,
    required this.isAr,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isInstaPay = method.code.contains('INSTAPAY');
    final activeIdentifier = method.accountIdentifier.isNotEmpty
        ? method.accountIdentifier
        : receivingPhone;

    final step1Text = isInstaPay
        ? (isAr
              ? 'افتح تطبيق إنستاباي وحوّل المبلغ المطلوب'
              : 'Open InstaPay and transfer the exact amount.')
        : (isAr
              ? 'افتح محفظتك وحوّل المبلغ المطلوب'
              : 'Open your wallet and transfer the exact amount.');

    final step2Text = isAr
        ? 'احتفظ بإيصال أو رسالة تأكيد التحويل'
        : 'Keep the confirmation message or receipt.';

    final step3Text = isAr
        ? 'ارجع هنا وأرسل تفاصيل التحويل'
        : 'Return here and submit your transfer details.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main details card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Provider logo + name + subtitle
              Row(
                children: [
                  _ProviderLogoWidget(assetPath: logoAsset, isSelected: true),
                  AppSpacing.gapW10,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.localizedName(isAr),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isInstaPay
                              ? (isAr
                                    ? 'حساب أو عنوان إنستاباي'
                                    : 'InstaPay account / IPA')
                              : (isAr
                                    ? 'رقم محفظة إلكترونية'
                                    : 'Mobile wallet'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),

              // Label: Transfer To
              Text(
                l10n.transferTo,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 5),

              // Receiver value + Copy action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      activeIdentifier,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => onCopy(activeIdentifier, l10n.numberCopied),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          AppSpacing.gapW4,
                          Text(
                            l10n.copyNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.gapH10,

        // Compact 3-step instructions box (no redundant paragraph above)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNumberedStep(1, step1Text),
              AppSpacing.gapH8,
              _buildNumberedStep(2, step2Text),
              AppSpacing.gapH8,
              _buildNumberedStep(3, step3Text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dedicated provider logo widget (~46-54 logical px)
/// Dedicated provider logo widget that displays the entire logo without cropping/clipping.
/// Sizes proportionally to provider aspect ratio (wider for InstaPay).
class _ProviderLogoWidget extends StatelessWidget {
  final String assetPath;
  final bool isSelected;

  const _ProviderLogoWidget({required this.assetPath, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final isInstaPay = assetPath.toLowerCase().contains('instapay');
    final containerWidth = isInstaPay ? 78.0 : 66.0;
    const containerHeight = 40.0;

    return Container(
      width: containerWidth,
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Failed to load asset ($assetPath): $error');
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
