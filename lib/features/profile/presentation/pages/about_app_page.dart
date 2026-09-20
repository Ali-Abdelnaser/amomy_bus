import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/assets/app_assets.dart';
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

/// Dedicated native screen describing AMOMY Bus and developer credentials.
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

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
    final developer = ProfilePlaceholderConfig.developer;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.aboutAmomyApp, showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo & App Name Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        AppAssets.logoTransparent,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              AppIcons.bus,
                              size: 40,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    AppSpacing.gapH12,
                    Text(
                      'AMOMY Bus',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Text(
                      l10n.appVersion('1.0.0'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,

              // App Description & Feature Capabilities
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aboutAppDescription,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    AppSpacing.gapH16,
                    _BulletFeature(text: l10n.aboutFeature1),
                    _BulletFeature(text: l10n.aboutFeature2),
                    _BulletFeature(text: l10n.aboutFeature3),
                    _BulletFeature(text: l10n.aboutFeature4),
                    _BulletFeature(text: l10n.aboutFeature5),
                    _BulletFeature(text: l10n.aboutFeature6),
                    _BulletFeature(text: l10n.aboutFeature7),
                  ],
                ),
              ),
              AppSpacing.gapH24,

              // Developer Section (Single Centralized Config Source)
              ProfileSection(
                title: l10n.developerSection.toUpperCase(),
                children: [
                  ProfileSettingTile(
                    icon: AppIcons.userRound,
                    title: l10n.developerNameLabel,
                    subtitle: developer.developerName,
                    showChevron: false,
                  ),
                  ProfileSettingTile(
                    icon: AppIcons.email,
                    title: l10n.developerEmailLabel,
                    subtitle: developer.developerEmail,
                    showChevron: false,
                    trailingWidget: const Icon(
                      AppIcons.copy,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _copyToClipboard(
                      context,
                      developer.developerEmail,
                      l10n.developerEmailLabel,
                    ),
                  ),
                  ProfileSettingTile(
                    icon: AppIcons.globe,
                    title: l10n.developerWebsiteLabel,
                    subtitle: developer.developerWebsite,
                    showChevron: false,
                    trailingWidget: const Icon(
                      AppIcons.copy,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _copyToClipboard(
                      context,
                      developer.developerWebsite,
                      l10n.developerWebsiteLabel,
                    ),
                  ),
                  ProfileSettingTile(
                    icon: AppIcons.externalLink,
                    title: l10n.developerLinkedInLabel,
                    subtitle: developer.developerLinkedIn,
                    showChevron: false,
                    trailingWidget: const Icon(
                      AppIcons.copy,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _copyToClipboard(
                      context,
                      developer.developerLinkedIn,
                      l10n.developerLinkedInLabel,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH24,

              // Copyright
              Center(
                child: Text(
                  '© ${DateTime.now().year} AMOMY. ${l10n.allRightsReserved}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
              AppSpacing.gapH16,
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletFeature extends StatelessWidget {
  final String text;

  const _BulletFeature({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.gapW10,
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
