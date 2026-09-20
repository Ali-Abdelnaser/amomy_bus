import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../data/models/profile_configs.dart';
import '../widgets/profile_section.dart';
import '../widgets/profile_setting_tile.dart';

/// Dedicated native Support Center screen.
///
/// Complies with AMOMY passenger standards:
/// - Soft brand circular headphones hero
/// - Documented placeholder contact channels from [ProfilePlaceholderConfig.support]
/// - Safe clipboard actions with localized feedback
/// - Lightweight interactive FAQ accordion
class SupportCenterPage extends StatelessWidget {
  const SupportCenterPage({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.showSuccess(
      context,
      '${context.l10n.copiedToClipboard}: $text',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final contact = ProfilePlaceholderConfig.support;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.supportCenter, showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Icon + Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    AppIcons.headphones,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.gapH16,
              Text(
                l10n.supportHeroTitle,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH6,
              Text(
                l10n.supportHeroSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH24,

              // Contact Channels Section
              ProfileSection(
                title: isAr ? 'قنوات التواصل' : 'CONTACT CHANNELS',
                children: [
                  ProfileSettingTile(
                    icon: AppIcons.email,
                    title: l10n.emailSupport,
                    subtitle: contact.supportEmail,
                    showChevron: false,
                    trailingWidget: const Icon(
                      AppIcons.copy,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _copyToClipboard(
                      context,
                      contact.supportEmail,
                      l10n.emailSupport,
                    ),
                  ),
                  ProfileSettingTile(
                    icon: AppIcons.phone,
                    title: l10n.callUs,
                    subtitle: contact.supportPhone,
                    showChevron: false,
                    trailingWidget: const Icon(
                      AppIcons.copy,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _copyToClipboard(
                      context,
                      contact.supportPhone,
                      l10n.callUs,
                    ),
                  ),
                  ProfileSettingTile(
                    icon: AppIcons.messageCircle,
                    title: l10n.whatsApp,
                    subtitle: contact.whatsAppNumber,
                    showChevron: false,
                    trailingWidget: const Icon(
                      AppIcons.copy,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _copyToClipboard(
                      context,
                      contact.whatsAppNumber,
                      l10n.whatsApp,
                    ),
                  ),
                  ProfileSettingTile(
                    icon: AppIcons.clock,
                    title: l10n.workingHours,
                    subtitle: isAr
                        ? contact.workingHoursAr
                        : contact.workingHoursEn,
                    showChevron: false,
                  ),
                ],
              ),
              AppSpacing.gapH24,

              // Frequently Asked Questions Section
              ProfileSection(
                title: l10n.frequentlyAskedQuestions.toUpperCase(),
                children: [
                  _FaqTile(
                    question: l10n.faqQuestion1,
                    answer: l10n.faqAnswer1,
                  ),
                  _FaqTile(
                    question: l10n.faqQuestion2,
                    answer: l10n.faqAnswer2,
                  ),
                  _FaqTile(
                    question: l10n.faqQuestion3,
                    answer: l10n.faqAnswer3,
                  ),
                ],
              ),
              AppSpacing.gapH32,
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          collapsedIconColor: AppColors.textTertiary,
          iconColor: AppColors.primary,
          title: Text(
            question,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
