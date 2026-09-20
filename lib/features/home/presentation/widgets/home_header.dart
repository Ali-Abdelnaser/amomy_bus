import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../auth/domain/entities/app_user.dart';

class HomeHeader extends StatelessWidget {
  final AppUser user;

  const HomeHeader({super.key, required this.user});

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = context.l10n;
    if (hour >= 5 && hour < 12) {
      return l10n.greetingMorning;
    } else if (hour >= 12 && hour < 17) {
      return l10n.greetingAfternoon;
    } else {
      return l10n.greetingEvening;
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting(context);
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
            child: !hasAvatar
                ? Text(
                    user.initials,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        AppSpacing.gapW12,

        // Greeting & Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapH4,
              Text(
                '${user.firstName} 👋',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Notification Icon Placeholder
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(
              AppIcons.notification,
              size: 22,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              AppSnackBar.showInfo(context, context.l10n.noData);
            },
          ),
        ),
      ],
    );
  }
}
