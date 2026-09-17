import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Centered identity header for Passenger Profile.
///
/// Features:
/// - Large circular avatar with initials fallback
/// - Interactive camera badge overlapping lower edge with RTL awareness
/// - Direct avatar photo capture, gallery picker, and removal
/// - User full name and muted email without repeating technical IDs
class ProfileIdentityHeader extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onAvatarModified;

  const ProfileIdentityHeader({
    super.key,
    required this.user,
    this.onAvatarModified,
  });

  bool get hasAvatar =>
      user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;

  void _showAvatarOptionsSheet(BuildContext context) {
    final l10n = context.l10n;
    final profileBloc = context.read<ProfileBloc>();
    final picker = ImagePicker();

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => AmomySheetContainer(
        hasBottomNav: true,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppIcons.camera,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.takePhoto,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                try {
                  final file = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    final ext = file.name.contains('.')
                        ? file.name.split('.').last
                        : 'jpg';
                    profileBloc.add(
                      ProfileAvatarUploadRequested(
                        userId: user.id,
                        imageBytes: bytes,
                        fileExtension: ext,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.avatarUpdateFailed),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppIcons.gallery,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.chooseFromPhotos,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                try {
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    final ext = file.name.contains('.')
                        ? file.name.split('.').last
                        : 'jpg';
                    profileBloc.add(
                      ProfileAvatarUploadRequested(
                        userId: user.id,
                        imageBytes: bytes,
                        fileExtension: ext,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.avatarUpdateFailed),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            if (hasAvatar) ...[
              const Divider(
                height: 1,
                indent: 64,
                color: AppColors.borderSubtle,
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    AppIcons.trash,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.removePhoto,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  profileBloc.add(
                    ProfileAvatarRemoveRequested(
                      userId: user.id,
                      currentAvatarUrl: user.avatarUrl,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final isLoading = profileState is ProfileAvatarLoading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar (116px diameter) + Camera Badge
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 156,
                    height: 156,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Color(0x0A0F172A),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: hasAvatar
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        onBackgroundImageError: hasAvatar
                            ? (exception, stackTrace) {}
                            : null,
                        child: (!hasAvatar)
                            ? Text(
                                user.initials,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 34,
                                  letterSpacing: 1.5,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0x66FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Camera edit badge sitting cleanly at lower trailing edge
                  PositionedDirectional(
                    end: -2,
                    bottom: -2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('profile_camera_badge'),
                        onTap: isLoading
                            ? null
                            : () => _showAvatarOptionsSheet(context),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x24000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            AppIcons.camera,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH16,

            // Full Name
            Text(
              user.fullName.trim().isNotEmpty
                  ? user.fullName
                  : context.l10n.navProfile,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH4,

            // Email (muted)
            Text(
              user.email,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH10,

            // Visual Status Chips (Passenger + Verified)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.bus,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      AppSpacing.gapW4,
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'راكب'
                            : 'Passenger',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDarker,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapW8,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.check,
                        size: 12,
                        color: AppColors.success,
                      ),
                      AppSpacing.gapW4,
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'موثق'
                            : 'Verified',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF027A48),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
