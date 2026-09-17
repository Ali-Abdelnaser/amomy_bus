import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../../core/localization/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_identity_header.dart';
import '../widgets/profile_section.dart';
import '../widgets/profile_setting_tile.dart';

/// Redesigned Passenger Profile Page.
///
/// Features:
/// - Clean, calm, modern visual hierarchy without heavy container cards
/// - Centered identity header directly on surface with interactive camera badge
/// - Real avatar capture, gallery selection, and removal with Supabase Storage
/// - Dedicated navigation to Personal Information, Notifications, Support, About, Privacy, and Terms
/// - Instant in-app language switching via modal bottom sheet
/// - Elegant non-destructive AMOMY Blue sign-out action with confirmation
class ProfilePage extends StatefulWidget {
  final ProfileBloc? profileBloc;

  const ProfilePage({super.key, this.profileBloc});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileBloc _profileBloc;
  bool _createdBloc = false;

  @override
  void initState() {
    super.initState();
    if (widget.profileBloc != null) {
      _profileBloc = widget.profileBloc!;
    } else if (getIt.isRegistered<ProfileBloc>()) {
      _profileBloc = getIt<ProfileBloc>();
    } else {
      _profileBloc = ProfileBloc(
        repository: getIt.isRegistered<ProfileRepository>()
            ? getIt<ProfileRepository>()
            : ProfileRepositoryImpl(),
      );
      _createdBloc = true;
    }
  }

  @override
  void dispose() {
    if (_createdBloc) {
      _profileBloc.close();
    }
    super.dispose();
  }

  void _showLanguageSelector(BuildContext context) {
    final controller = AppLocaleController.instance;
    final l10n = context.l10n;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => AmomySheetContainer(
        hasBottomNav: true,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.language,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH16,
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              minVerticalPadding: 12,
              selected: controller.isArabic,
              selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppIcons.languages,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                'العربية',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: controller.isArabic
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: controller.isArabic
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              trailing: controller.isArabic
                  ? const Icon(
                      AppIcons.check,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
              onTap: () {
                if (!controller.isArabic) {
                  controller.setLocale(LocalizationHelper.arabicLocale);
                }
                Navigator.of(ctx).pop();
              },
            ),
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 60),
              child: Divider(height: 12, color: AppColors.borderSubtle),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              minVerticalPadding: 12,
              selected: !controller.isArabic,
              selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppIcons.languages,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                'English',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: !controller.isArabic
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: !controller.isArabic
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              trailing: !controller.isArabic
                  ? const Icon(
                      AppIcons.check,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
              onTap: () {
                if (controller.isArabic) {
                  controller.setLocale(LocalizationHelper.englishLocale);
                }
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final l10n = context.l10n;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => AmomySheetContainer(
        hasBottomNav: true,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.logOut,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              AppSpacing.gapH16,
              Text(
                l10n.signOutConfirmTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.signOutConfirmMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH24,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.read<AuthBloc>().add(const SignOutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        l10n.signOut,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return BlocProvider<ProfileBloc>.value(
      value: _profileBloc,
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, profileState) {
          if (profileState is ProfileAvatarSuccess) {
            final authBloc = context.read<AuthBloc>();
            final authState = authBloc.state;
            if (authState is Authenticated) {
              final updatedUser = authState.user.copyWith(
                avatarUrl: profileState.avatarUrl,
              );
              authBloc.add(AuthUserChangedInternal(updatedUser));
            }
            AppSnackBar.showSuccess(
              context,
              profileState.isRemoved
                  ? l10n.avatarRemovedSuccess
                  : l10n.avatarUpdatedSuccess,
            );
          } else if (profileState is ProfileAvatarFailure) {
            AppSnackBar.showError(context, profileState.message);
          }
        },
        builder: (context, profileState) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is! Authenticated) {
                return const AppScaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final user = authState.user;

              return AppScaffold(
                backgroundColor: const Color(0xFFF6F8FB),
                appBar: AppAppBar(
                  title: l10n.navProfile,
                  showBackButton: false,
                ),
                body: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Centered Identity Header directly on surface
                        ProfileIdentityHeader(user: user),
                        AppSpacing.gapH24,

                        // SECTION 1: ACCOUNT
                        ProfileSection(
                          title: isAr ? 'الحساب' : 'ACCOUNT',
                          children: [
                            ProfileSettingTile(
                              icon: AppIcons.userRound,
                              title: l10n.personalInfo,
                              subtitle: isAr
                                  ? 'تحديث بياناتك وتفاصيل الاتصال'
                                  : 'Update your personal details',
                              iconBackgroundColor: const Color(0xFFE8F1FA),
                              iconColor: AppColors.primary,
                              onTap: () =>
                                  context.push(RoutePaths.personalInformation),
                            ),
                          ],
                        ),
                        AppSpacing.gapH18,

                        // SECTION 2: PREFERENCES
                        ProfileSection(
                          title: isAr ? 'التفضيلات' : 'PREFERENCES',
                          children: [
                            ProfileSettingTile(
                              icon: AppIcons.notification,
                              title: l10n.notificationSettings,
                              subtitle: isAr
                                  ? 'إدارة التنبيهات وتحديثات الرحلات'
                                  : 'Manage alerts and trip updates',
                              iconBackgroundColor: const Color(0xFFFEF3EB),
                              iconColor: const Color(0xFFE06D14),
                              onTap: () =>
                                  context.push(RoutePaths.notificationSettings),
                            ),
                            ProfileSettingTile(
                              icon: AppIcons.languages,
                              title: l10n.language,
                              subtitle: isAr
                                  ? 'اختر لغة التطبيق المفضلة'
                                  : 'Choose your preferred app language',
                              trailingText: isAr ? 'العربية' : 'English',
                              iconBackgroundColor: const Color(0xFFEEF4FF),
                              iconColor: const Color(0xFF3538CD),
                              onTap: () => _showLanguageSelector(context),
                            ),
                          ],
                        ),
                        AppSpacing.gapH18,

                        // SECTION 3: HELP & SUPPORT
                        ProfileSection(
                          title: isAr ? 'المساعدة والدعم' : 'HELP & SUPPORT',
                          children: [
                            ProfileSettingTile(
                              icon: AppIcons.headphones,
                              title: l10n.supportCenter,
                              subtitle: isAr
                                  ? 'تحتاج مساعدة؟ تواصل معنا'
                                  : 'Need help? Contact us',
                              iconBackgroundColor: const Color(0xFFECFDF3),
                              iconColor: const Color(0xFF027A48),
                              onTap: () => context.push(RoutePaths.support),
                            ),
                          ],
                        ),
                        AppSpacing.gapH18,

                        // SECTION 4: ABOUT & LEGAL
                        ProfileSection(
                          title: isAr
                              ? 'حول التطبيق والقانونية'
                              : 'ABOUT & LEGAL',
                          children: [
                            ProfileSettingTile(
                              icon: AppIcons.info,
                              title: l10n.aboutAmomyApp,
                              subtitle: isAr
                                  ? 'إصدار التطبيق ومعلومات المطور'
                                  : 'App version and developer info',
                              iconBackgroundColor: const Color(0xFFF4F3FF),
                              iconColor: const Color(0xFF5925DC),
                              onTap: () => context.push(RoutePaths.aboutApp),
                            ),
                            ProfileSettingTile(
                              icon: AppIcons.shield,
                              title: l10n.privacyPolicy,
                              subtitle: isAr
                                  ? 'حماية وأمان بياناتك الشخصية'
                                  : 'Data privacy and security standards',
                              iconBackgroundColor: const Color(0xFFF8F9FC),
                              iconColor: const Color(0xFF475467),
                              onTap: () =>
                                  context.push(RoutePaths.privacyPolicy),
                            ),
                            ProfileSettingTile(
                              icon: AppIcons.fileText,
                              title: l10n.termsAndConditions,
                              subtitle: isAr
                                  ? 'شروط الاستخدام وقواعد الخدمة'
                                  : 'Terms of use and service rules',
                              iconBackgroundColor: const Color(0xFFF8F9FC),
                              iconColor: const Color(0xFF475467),
                              onTap: () =>
                                  context.push(RoutePaths.termsAndConditions),
                            ),
                          ],
                        ),
                        AppSpacing.gapH24,

                        // LOGOUT / DESTRUCTIVE ACTION: Distinct full-width soft red outlined style
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmSignOut(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3F2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFECDCA),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    AppIcons.logOut,
                                    size: 19,
                                    color: AppColors.error,
                                  ),
                                  AppSpacing.gapW8,
                                  Text(
                                    l10n.signOut,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        AppSpacing.gapBottomNav,
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
