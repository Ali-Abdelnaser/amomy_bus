import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/assets/app_assets.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/localization_helpers.dart';
import '../../../../core/theme/app_spacing.dart';

/// Premium booking hero card with full background bus artwork and integrated wallet points balance.
///
/// Fully locale-aware mirrored composition:
/// - English (LTR): Text & CTA on the left, bus artwork emphasis on the right.
/// - Arabic (RTL): Text & CTA on the right, bus artwork emphasis on the left (horizontally flipped).
/// - Full-bleed background layer with subtle directional gradient overlay for crystal-clear readability.
class HomeBookRideCard extends StatelessWidget {
  final int points;
  final bool isBookingAvailable;
  final bool hasLoadedAvailability;

  const HomeBookRideCard({
    super.key,
    required this.points,
    this.isBookingAvailable = true,
    this.hasLoadedAvailability = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRtl = context.isRtl;
    final formatter = NumberFormat('#,###');
    final formattedPoints = formatter.format(points);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final textMaxWidth = cardWidth * 0.56;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFDCE7F3).withValues(alpha: 0.8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF01589F).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. Full-bleed Hero Bus Artwork Background (mirrored and flipped for Arabic)
                Positioned.fill(
                  child: isRtl
                      ? Transform.flip(
                          flipX: true,
                          child: Image.asset(
                            AppAssets.bookCardBg,
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                          ),
                        )
                      : Image.asset(
                          AppAssets.bookCardBg,
                          fit: BoxFit.cover,
                          alignment: Alignment.centerRight,
                        ),
                ),

                // 2. Directional Gradient Overlay (ensures text readability while highlighting bus artwork)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        colors: [
                          const Color(0xFFEFF6FC).withValues(alpha: 0.94),
                          const Color(0xFFEFF6FC).withValues(alpha: 0.84),
                          const Color(0xFFEFF6FC).withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.40, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Interactive Content Layer
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: FAST & DIRECT tag (Start) + Points Pill (End)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.homeFastDirect,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF01589F),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),

                          // Points Balance Pill with Wallet Icon
                          GestureDetector(
                            onTap: () => context.push('/add-points'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFDCE8F4),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFC928),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        AppIcons.wallet,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.gapW6,
                                  Text(
                                    '$formattedPoints ${l10n.pointsUnit}',
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0C2442),
                                    ),
                                  ),
                                  AppSpacing.gapW4,
                                  Icon(
                                    isRtl
                                        ? AppIcons.chevronLeft
                                        : AppIcons.chevronRight,
                                    size: 13,
                                    color: const Color(0xFF01589F),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Text Section: Title + Subtitle + CTA Button (aligned to start)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: textMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.bookRideTitle,
                              style: const TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A1D37),
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.bookRideSubtitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),

                            // CTA Button: Book Now -> respects booking cutoff availability
                            Builder(
                              builder: (context) {
                                final isBookingClosed =
                                    hasLoadedAvailability &&
                                    !isBookingAvailable;
                                final isEnabled = !isBookingClosed;
                                final buttonColor = isEnabled
                                    ? const Color(0xFF01589F)
                                    : const Color(0xFFCBD5E1);

                                return GestureDetector(
                                  key: const Key('home-book-ride-cta'),
                                  onTap: isEnabled
                                      ? () => context.push('/book-trip')
                                      : null,
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: buttonColor,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: isEnabled
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF01589F,
                                                ).withValues(alpha: 0.28),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isEnabled
                                                ? l10n.bookNow
                                                : (context.isArabic
                                                      ? 'الحجز مغلق'
                                                      : 'Booking closed'),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (isEnabled) ...[
                                            AppSpacing.gapW8,
                                            Icon(
                                              isRtl
                                                  ? AppIcons.arrowBack
                                                  : AppIcons.arrowForward,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
