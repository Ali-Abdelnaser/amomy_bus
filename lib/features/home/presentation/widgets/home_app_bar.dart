import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeAppBar extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  final int unreadNotificationsCount;

  const HomeAppBar({
    super.key,
    required this.fullName,
    this.avatarUrl,
    this.unreadNotificationsCount = 0,
  });

  String _getInitials() {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'P';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return SizedBox(
      height: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. One side: Notification Icon Button
          Material(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                context.push(RoutePaths.notifications);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        AppIcons.notification,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (unreadNotificationsCount > 0)
                      PositionedDirectional(
                        top: -4,
                        end: -4,
                        child: _UnreadBadge(count: unreadNotificationsCount),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. In Center: AMOMY logo (matching container size) + "AMOMY" English wordmark only
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.logoTransparent,
                height: 45,
                fit: BoxFit.cover,
              ),
              AppSpacing.gapW8,
              Text(
                'AMOMY',
                style: GoogleFonts.openSans(
                  color: AppColors.primaryDarker,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),

          // 3. Other side: Profile Avatar (tap -> Edit Profile)
          GestureDetector(
            onTap: () => context.push('/complete-profile'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                child: !hasAvatar
                    ? Text(
                        initials,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
