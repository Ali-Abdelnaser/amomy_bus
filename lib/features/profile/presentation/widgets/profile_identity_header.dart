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
            // Circular Avatar + Camera Badge
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 80,
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
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
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
                  // Camera edit badge overlapping edge
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('profile_camera_badge'),
                        onTap: isLoading
                            ? null
                            : () => _showAvatarOptionsSheet(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            AppIcons.camera,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH12,

            // Full Name
            Text(
              user.fullName.trim().isNotEmpty
                  ? user.fullName
                  : context.l10n.navProfile,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH4,

            // Email (muted)
            Text(
              user.email,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
