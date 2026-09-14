import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../services/notification_service.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationCubit(
        repository: getIt<NotificationRepository>(),
        notificationService: getIt.isRegistered<NotificationService>()
            ? getIt<NotificationService>()
            : null,
      )..loadNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';

    final title = isAr ? 'الإشعارات' : 'Notifications';
    final markAllReadText = isAr ? 'تحديد الكل كمقروء' : 'Mark all as read';
    final emptyTitle = isAr ? 'لا توجد إشعارات' : 'No notifications';
    final emptySubtitle = isAr
        ? 'ستظهر هنا تحديثات رحلاتك وحجوزاتك واقتراب الأتوبيس'
        : 'Updates on your trips, bookings, and bus arrivals will appear here';
    final retryText = isAr ? 'إعادة المحاولة' : 'Retry';
    final todayText = isAr ? 'اليوم' : 'TODAY';
    final earlierText = isAr ? 'السابق' : 'EARLIER';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final hasUnread = state is NotificationLoaded && state.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
                child: Text(
                  markAllReadText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return _buildSkeletonList();
          }

          if (state is NotificationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.warningCircle, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<NotificationCubit>().loadNotifications(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(retryText),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => context.read<NotificationCubit>().loadNotifications(isRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceSoft,
                        ),
                        child: const Icon(
                          AppIcons.notification,
                          size: 36,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      emptyTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        emptySubtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            final todayList = state.notifications.where((n) => _isToday(n.createdAt)).toList();
            final earlierList = state.notifications.where((n) => !_isToday(n.createdAt)).toList();

            return RefreshIndicator(
              onRefresh: () => context.read<NotificationCubit>().loadNotifications(isRefresh: true),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. TODAY Section
                  if (todayList.isNotEmpty) ...[
                    _buildSectionHeader(todayText),
                    const SizedBox(height: 8),
                    ...todayList.map((notification) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NotificationTile(
                            notification: notification,
                            onMarkRead: () {
                              context.read<NotificationCubit>().markAsRead(notification.id);
                            },
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],

                  // 2. EARLIER Section
                  if (earlierList.isNotEmpty) ...[
                    _buildSectionHeader(earlierText),
                    const SizedBox(height: 8),
                    ...earlierList.map((notification) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NotificationTile(
                            notification: notification,
                            onMarkRead: () {
                              context.read<NotificationCubit>().markAsRead(notification.id);
                            },
                          ),
                        )),
                  ],
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    final dummy = AppNotification(
      id: 'dummy',
      userId: 'dummy',
      type: NotificationType.system,
      titleAr: 'جاري تحميل الإشعارات الخاصة بك',
      bodyAr: 'يرجى الانتظار لحظات ريثما يتم جلب أحدث الإشعارات والتنبيهات.',
      titleEn: 'Loading your notifications',
      bodyEn: 'Please wait while we retrieve the latest trip updates.',
      createdAt: DateTime.now(),
    );

    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => NotificationTile(notification: dummy),
      ),
    );
  }
}
