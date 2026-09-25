import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_loading.dart';
import '../cubit/passenger_trips_cubit.dart';
import '../cubit/passenger_trips_state.dart';
import '../widgets/preferred_journey_sheet.dart';
import '../widgets/today_trip_card.dart';

class MyTripsPage extends StatelessWidget {
  final PassengerTripsCubit? tripsCubit;

  const MyTripsPage({super.key, this.tripsCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          tripsCubit ??
          (getIt.isRegistered<PassengerTripsCubit>()
              ? (getIt<PassengerTripsCubit>()..loadTripsHub())
              : PassengerTripsCubit.idle()),
      child: const _MyTripsView(),
    );
  }
}

class _MyTripsView extends StatelessWidget {
  const _MyTripsView();

  String _formatDateSubtitle(bool isAr) {
    final now = DateTime.now();
    if (isAr) {
      final dayName = DateFormat('EEEE', 'ar').format(now);
      final dayNum = DateFormat('d', 'ar').format(now);
      final monthName = DateFormat('MMMM', 'ar').format(now);
      return '$dayName، $dayNum $monthName';
    } else {
      return DateFormat('EEEE, d MMMM', 'en').format(now);
    }
  }

  void _openSettings(BuildContext context, PassengerTripsState state) {
    PreferredJourneySheet.show(
      context,
      availableStops: state.availableStops,
      preference: state.preferredJourney,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PassengerTripsCubit, PassengerTripsState>(
          builder: (context, state) {
            return Column(
              children: [
                // 1. TOP BAR: [ SETTINGS ] — MY TRIPS (Mathematically Centered) — [ ADD ]
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Mathematically Centered Title
                        Center(
                          child: Builder(
                            builder: (context) {
                              Widget titleWidget = Text(
                                isAr ? 'رحلاتي' : 'My Trips',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF101828),
                                  letterSpacing: -0.4,
                                ),
                              );
                              if (!disableAnimations) {
                                titleWidget = titleWidget
                                    .animate()
                                    .fadeIn(
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    )
                                    .slideY(
                                      begin: -0.15,
                                      end: 0,
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                              }
                              return titleWidget;
                            },
                          ),
                        ),

                        // Action Buttons on Opposite Sides
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // LEFT: Settings button (Preferred Journey) - Glass / Blur Settings Gear
                            _HeaderSettingsButton(
                              tooltip: isAr
                                  ? 'تفضيلات الرحلة المعتادة'
                                  : 'Preferred Journey Settings',
                              disableAnimations: disableAnimations,
                              onTap: () => _openSettings(context, state),
                            ),

                            // RIGHT: Wider compact BOOK action [ + Book ] / [ + حجز ]
                            _HeaderBookButton(
                              isAr: isAr,
                              disableAnimations: disableAnimations,
                              isEnabled: !state.shouldDisableBookingEntry,
                              disabledMessage: isAr
                                  ? 'الحجز مغلق'
                                  : 'Booking closed',
                              onTap: () => context.push(RoutePaths.bookTrip),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. TODAY DATE & DEDICATED HISTORY TRIGGER ROW
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Date Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'اليوم' : 'Today',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF101828),
                            ),
                          ),
                          AppSpacing.gapH2,
                          Text(
                            _formatDateSubtitle(isAr),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      // Dedicated History button
                      _HistoryButton(
                        isAr: isAr,
                        onTap: () => context.push(RoutePaths.myBookings),
                      ),
                    ],
                  ),
                ),

                // 3. TODAY SCHEDULE BODY
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state.status == PassengerTripsStatus.loading &&
                          state.todayTrips.isEmpty) {
                        return const Center(child: AmomyBusLoading.medium());
                      }

                      if (state.todayTrips.isEmpty) {
                        return RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => context
                              .read<PassengerTripsCubit>()
                              .loadTripsHub(),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 36,
                            ),
                            children: [
                              Center(
                                child: Image.asset(
                                  AppAssets.busServiceIllustration,
                                  height: 350,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Text(
                                isAr
                                    ? 'لا توجد رحلات مجدولة لليوم'
                                    : 'No trips scheduled for today',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.gapH4,
                              Text(
                                isAr
                                    ? 'جداول تشغيل الحافلات لليوم انتهت أو ستبدأ قريبًا.'
                                    : 'Today\'s operational trips have concluded\nor will commence shortly.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.gapH20,
                              Center(
                                child: OutlinedButton.icon(
                                  onPressed: () => context
                                      .read<PassengerTripsCubit>()
                                      .loadTripsHub(),
                                  icon: const Icon(AppIcons.refresh, size: 16),
                                  label: Text(
                                    isAr ? 'تحديث الجدول' : 'Refresh Schedule',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final outbound = state.outboundTodayTrips;
                      final returnTrips = state.returnTodayTrips;

                      int globalCardIndex = 0;

                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            context.read<PassengerTripsCubit>().loadTripsHub(),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            AppSpacing.bottomNavClearance + 24,
                          ),
                          children: [
                            // OUTBOUND SECTION (Blue Identity)
                            if (outbound.isNotEmpty) ...[
                              _SectionHeader(
                                title: isAr ? 'رحلات الذهاب' : 'Outbound Trips',
                                count: outbound.length,
                                icon: Icons.east_rounded,
                                themeColor: AppColors.primary,
                                bgTint: const Color(0xFFEBF3FA),
                              ),
                              AppSpacing.gapH8,
                              ...outbound.map((trip) {
                                final idx = globalCardIndex++;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TodayTripCard(
                                    trip: trip,
                                    preference: state.preferredJourney,
                                    animationIndex: idx,
                                  ),
                                );
                              }),
                              AppSpacing.gapH12,
                            ],

                            // RETURN SECTION (Yellow / Gold Identity)
                            if (returnTrips.isNotEmpty) ...[
                              _SectionHeader(
                                title: isAr ? 'رحلات العودة' : 'Return Trips',
                                count: returnTrips.length,
                                icon: Icons.west_rounded,
                                themeColor: const Color(0xFFD49B00),
                                bgTint: const Color(0xFFFEF6E7),
                              ),
                              AppSpacing.gapH8,
                              ...returnTrips.map((trip) {
                                final idx = globalCardIndex++;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TodayTripCard(
                                    trip: trip,
                                    preference: state.preferredJourney,
                                    animationIndex: idx,
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Glass translucent blur Settings Button with tactile micro-interaction.
class _HeaderSettingsButton extends StatefulWidget {
  final String tooltip;
  final bool disableAnimations;
  final VoidCallback onTap;

  const _HeaderSettingsButton({
    required this.tooltip,
    required this.disableAnimations,
    required this.onTap,
  });

  @override
  State<_HeaderSettingsButton> createState() => _HeaderSettingsButtonState();
}

class _HeaderSettingsButtonState extends State<_HeaderSettingsButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    Widget button = Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isDown = true),
        onTapUp: (_) {
          setState(() => _isDown = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isDown = false),
        child: AnimatedScale(
          scale: _isDown ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: _isDown ? 0.022 : 0.0, // ~8 degrees
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.settings_rounded,
                      size: 21,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.disableAnimations) {
      button = button
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 260))
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            curve: Curves.easeOutCubic,
          );
    }

    return button;
  }
}

/// Wider compact BOOK action [ + Book ] / [ + حجز ]
/// White surface, primary blue border/text/icon, rounded capsule, tactile micro-interaction.
class _HeaderBookButton extends StatefulWidget {
  final bool isAr;
  final bool disableAnimations;
  final bool isEnabled;
  final String disabledMessage;
  final VoidCallback onTap;

  const _HeaderBookButton({
    required this.isAr,
    required this.disableAnimations,
    this.isEnabled = true,
    required this.disabledMessage,
    required this.onTap,
  });

  @override
  State<_HeaderBookButton> createState() => _HeaderBookButtonState();
}

class _HeaderBookButtonState extends State<_HeaderBookButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isEnabled
        ? Colors.white
        : const Color(0xFFF1F5F9);
    final background = widget.isEnabled
        ? AppColors.primary
        : const Color(0xFF94A3B8);

    Widget button = Tooltip(
      message: widget.isEnabled
          ? (widget.isAr ? 'حجز رحلة جديدة' : 'Book a New Trip')
          : widget.disabledMessage,
      child: GestureDetector(
        onTapDown: widget.isEnabled
            ? (_) => setState(() => _isDown = true)
            : null,
        onTapUp: (_) {
          setState(() => _isDown = false);
          if (widget.isEnabled) {
            widget.onTap();
          }
        },
        onTapCancel: () => setState(() => _isDown = false),
        child: AnimatedScale(
          scale: widget.isEnabled && _isDown ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: background.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: background.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: foreground),
                const SizedBox(width: 5),
                Text(
                  widget.isAr ? 'حجز' : 'Book',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.disableAnimations) {
      button = button
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 260))
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            curve: Curves.easeOutCubic,
          );
    }

    return button;
  }
}

/// History Trigger Pill Button with smooth tap micro-interaction.
class _HistoryButton extends StatefulWidget {
  final bool isAr;
  final VoidCallback onTap;

  const _HistoryButton({required this.isAr, required this.onTap});

  @override
  State<_HistoryButton> createState() => _HistoryButtonState();
}

class _HistoryButtonState extends State<_HistoryButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isAr ? 'سجل الرحلات' : 'Trip History',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isDown = true),
        onTapUp: (_) {
          setState(() => _isDown = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isDown = false),
        child: AnimatedScale(
          scale: _isDown ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCE7F3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                AppSpacing.gapW6,
                Text(
                  widget.isAr ? 'السجل' : 'History',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Distinct directional section header with subtle icon pill and counter.
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color themeColor;
  final Color bgTint;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.themeColor,
    required this.bgTint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 13, color: themeColor),
              ),
              AppSpacing.gapW8,
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: themeColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelSmall.copyWith(
                color: themeColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
