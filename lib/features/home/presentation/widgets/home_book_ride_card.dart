import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/assets/app_assets.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/localization_helpers.dart';
import '../../../../core/theme/app_spacing.dart';

/// Premium booking hero card with background bus illustration and integrated wallet points balance.
/// Matches the official AMOMY design with high visual fidelity in both RTL and LTR.
class HomeBookRideCard extends StatelessWidget {
  final int points;

  const HomeBookRideCard({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRtl = context.isRtl;
    final isAr = context.isArabic;
    final formatter = NumberFormat('#,###');
    final formattedPoints = formatter.format(points);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Text takes 54% width, leaving the remaining 46% for the bus on the trailing side
        final textMaxWidth = constraints.maxWidth * 0.54;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FC),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFDCE7F3).withValues(alpha: 0.75),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF01589F).withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // 1. Background Bus Artwork with perfectly balanced composition
                Positioned.fill(
                  child: Transform.flip(
                    flipX: isRtl,
                    child: Image.asset(
                      AppAssets.bookCardBg,
                      fit: BoxFit.cover,
                      alignment: isRtl
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                    ),
                  ),
                ),

                // 2. Card Interactive Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: FAST & DIRECT tag + Points Pill with Wallet Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Fast & Direct Badge (discreet and elegant)
                          Text(
                            isAr ? 'سريع ومباشر' : 'FAST & DIRECT',
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF01589F),
                              letterSpacing: 1.1,
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
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFDCE8F4),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Amber circle with Wallet Icon
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFC928),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        AppIcons.wallet,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.gapW6,
                                  Text(
                                    '$formattedPoints ${l10n.pointsUnit}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0C2442),
                                    ),
                                  ),
                                  AppSpacing.gapW4,
                                  Icon(
                                    isRtl
                                        ? AppIcons.chevronLeft
                                        : AppIcons.chevronRight,
                                    size: 14,
                                    color: const Color(0xFF01589F),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH16,

                      // Leading Text Section: Title + Subtitle + CTA Button
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: textMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.bookRideTitle,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A1D37),
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                            ),
                            AppSpacing.gapH8,
                            Text(
                              l10n.bookRideSubtitle,
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5A728D),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AppSpacing.gapH18,

                            // CTA Button: Book Now ->
                            GestureDetector(
                              onTap: () => context.push('/book-trip'),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF01589F),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF01589F,
                                      ).withValues(alpha: 0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.bookNow,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    AppSpacing.gapW8,
                                    Icon(
                                      isRtl
                                          ? AppIcons.arrowBack
                                          : AppIcons.arrowForward,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
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
