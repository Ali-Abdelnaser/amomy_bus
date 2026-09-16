import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/notification_event_catalog.dart';
import '../../domain/entities/notification_test_event_result.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/notification_router.dart';

/// Interactive modal sheet providing the AMOMY Notification Test Lab.
///
/// Restricted to authorized server-backed tester accounts.
/// Simulates authoritative production notification events through the real
/// backend pipeline (DB insertion -> preference evaluation -> FCM delivery).
class NotificationTestLabSheet extends StatefulWidget {
  const NotificationTestLabSheet({super.key});

  /// Displays the Test Lab bottom sheet above the entire shell and bottom nav bar.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationTestLabSheet(),
    );
  }

  @override
  State<NotificationTestLabSheet> createState() => _NotificationTestLabSheetState();
}

class _NotificationTestLabSheetState extends State<NotificationTestLabSheet> {
  bool _forceDelivery = false;
  String? _selectedCategory;
  String? _activeSendingEvent;
  final Map<String, NotificationTestEventResult> _results = {};

  NotificationRepository get _repository => getIt<NotificationRepository>();

  Future<void> _sendTestEvent(NotificationEventDefinition event) async {
    if (_activeSendingEvent != null) return;

    setState(() {
      _activeSendingEvent = event.eventType;
    });

    try {
      final result = await _repository.sendTestEvent(
        eventType: event.eventType,
        forceDelivery: _forceDelivery,
        customData: event.samplePayload,
      );

      if (mounted) {
        setState(() {
          _results[event.eventType] = result;
          _activeSendingEvent = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results[event.eventType] = NotificationTestEventResult.failure(
            e.toString(),
            eventType: event.eventType,
          );
          _activeSendingEvent = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final events = NotificationEventCatalog.allEvents.where((e) {
      if (_selectedCategory == null) return true;
      return e.category.toDbKey() == _selectedCategory;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.flaskConical,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'مختبر الإشعارات' : 'Notification Test Lab',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'محاكاة أحداث الإشعارات الحقيقية وفحص الإرسال'
                            : 'Simulate real production events & push delivery',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),

          // Delivery Mode Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'وضع فحص التفضيلات:' : 'Preference Test Mode:',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeChip(
                          title: isAr ? 'احترام التفضيلات' : 'Respect Preferences',
                          subtitle: isAr ? 'يفحص التصفية الحقيقية' : 'Tests real filtering',
                          isSelected: !_forceDelivery,
                          onTap: () => setState(() => _forceDelivery = false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeChip(
                          title: isAr ? 'إرسال إجباري' : 'Force Test Delivery',
                          subtitle: isAr ? 'تجاوز تفضيلات الفئة' : 'Bypasses category toggle',
                          isSelected: _forceDelivery,
                          onTap: () => setState(() => _forceDelivery = true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _CategoryFilterChip(
                  label: isAr ? 'الكل (15)' : 'All (15)',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                _CategoryFilterChip(
                  label: isAr ? 'الخدمة (3)' : 'Service (3)',
                  isSelected: _selectedCategory == 'service_updates',
                  onTap: () => setState(() => _selectedCategory = 'service_updates'),
                ),
                const SizedBox(width: 8),
                _CategoryFilterChip(
                  label: isAr ? 'الحجز (3)' : 'Booking (3)',
                  isSelected: _selectedCategory == 'booking_updates',
                  onTap: () => setState(() => _selectedCategory = 'booking_updates'),
                ),
                const SizedBox(width: 8),
                _CategoryFilterChip(
                  label: isAr ? 'المحفظة (4)' : 'Wallet (4)',
                  isSelected: _selectedCategory == 'wallet_updates',
                  onTap: () => setState(() => _selectedCategory = 'wallet_updates'),
                ),
                const SizedBox(width: 8),
                _CategoryFilterChip(
                  label: isAr ? 'التتبع (5)' : 'Tracking (5)',
                  isSelected: _selectedCategory == 'trip_updates',
                  onTap: () => setState(() => _selectedCategory = 'trip_updates'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Event Catalog List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                final isSending = _activeSendingEvent == event.eventType;
                final result = _results[event.eventType];

                return _EventTestCard(
                  event: event,
                  isSending: isSending,
                  result: result,
                  isAr: isAr,
                  onSend: () => _sendTestEvent(event),
                  onTapDestination: () {
                    NotificationRouter.navigateToDestination(event.samplePayload);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EventTestCard extends StatelessWidget {
  final NotificationEventDefinition event;
  final bool isSending;
  final NotificationTestEventResult? result;
  final bool isAr;
  final VoidCallback onSend;
  final VoidCallback onTapDestination;

  const _EventTestCard({
    required this.event,
    required this.isSending,
    required this.result,
    required this.isAr,
    required this.onSend,
    required this.onTapDestination,
  });

  @override
  Widget build(BuildContext context) {
    final title = isAr ? event.titleAr : event.titleEn;
    final body = isAr ? event.bodyAr : event.bodyEn;
    final categoryName = event.category.localizedName(Locale(isAr ? 'ar' : 'en'));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: result != null
              ? (result!.success ? AppColors.success.withAlpha(120) : AppColors.error.withAlpha(120))
              : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  event.icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.eventType,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Example Body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              body,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Actions Row
          Row(
            children: [
              // Deep Link preview / test
              InkWell(
                onTap: onTapDestination,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.compass,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/${event.destinationScreen}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Send Test Button
              ElevatedButton(
                onPressed: isSending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(90, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.send, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'إرسال تجربة' : 'Send Test',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),

          // Result feedback banner
          if (result != null) ...[
            const SizedBox(height: 8),
            _ResultFeedbackBanner(result: result!, isAr: isAr),
          ],
        ],
      ),
    );
  }
}

class _ResultFeedbackBanner extends StatelessWidget {
  final NotificationTestEventResult result;
  final bool isAr;

  const _ResultFeedbackBanner({
    required this.result,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String statusText;

    if (result.preferenceSuppressed) {
      bg = Colors.amber.shade50;
      border = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      icon = LucideIcons.bellOff;
      statusText = isAr
          ? 'تم حفظ الإشعار بالصندوق، وحُجب الإشعار الفوري بناءً على تفضيلاتك'
          : 'Inbox saved. Push suppressed by user preference toggle.';
    } else if (result.success) {
      bg = AppColors.successLight;
      border = AppColors.success;
      textColor = AppColors.success;
      icon = LucideIcons.circleCheck;
      statusText = isAr
          ? 'تم الإرسال بنجاح (${result.delivered}/${result.totalDevices} أجهزة) • الصندوق: ${result.inboxInserted ? "محفوظ" : "تخطي"}'
          : 'Delivered (${result.delivered}/${result.totalDevices} devices) • Inbox: ${result.inboxInserted ? "Saved" : "Skipped"}';
    } else {
      bg = AppColors.errorLight;
      border = AppColors.error;
      textColor = AppColors.error;
      icon = LucideIcons.circleAlert;
      final rawError = result.error ?? '';
      if (rawError.contains('Notification Test Lab access denied') || rawError.contains('restricted to authorized testers')) {
        statusText = isAr ? 'فشل الإرسال: غير مصرح للحساب بالوصول لمختبر الإشعارات' : 'Failed to send test: Tester authorization failed.';
      } else if (rawError.contains('No active device') || rawError.contains('No registered active device')) {
        statusText = isAr ? 'فشل الإرسال: لا توجد أجهزة نشطة مسجلة للإشعارات' : 'Failed to send test: No active notification device found.';
      } else if (rawError.toLowerCase().contains('apns') ||
          rawError.toLowerCase().contains('invalid apns') ||
          rawError.toLowerCase().contains('third_party_auth_error') ||
          rawError.contains('Apple push credentials')) {
        statusText = isAr
            ? 'بيانات اعتماد دفع Apple (APNs) غير مهيأة بشكل صحيح.'
            : 'Apple push credentials are not configured correctly.';
      } else if (rawError.contains('suppressed')) {
        statusText = isAr ? 'تم حجب الإشعار بناءً على إعدادات التفضيلات' : 'Test suppressed by notification preferences.';
      } else if (rawError.isNotEmpty) {
        statusText = rawError;
      } else {
        statusText = isAr ? 'فشل إرسال إشعار التجربة' : 'Failed to deliver test notification';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: AppTextStyles.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
