import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/amomy_bus_icon.dart';
import '../../domain/entities/announcement.dart';

/// Premium asymmetrical AMOMY announcement and offer card.
/// Features a branded primary surface, slanted yellow accent, visible bus artwork, and route line details.
class AmomyAnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AmomyAnnouncementCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final title = announcement.localizedTitle(locale);
    final description = announcement.localizedDescription(locale);
    final isOffer = announcement.isOffer;

    return Container(
      width: 290,
      margin: const EdgeInsetsDirectional.only(end: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarker.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Asymmetrical diagonal accent ribbon in top-start corner
            PositionedDirectional(
              start: -12,
              top: -12,
              child: Transform.rotate(
                angle: -0.25,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentYellow.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Tonal blue depth in background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDarker],
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                ),
              ),
            ),

            // 3. Subtle route track line and dots on opposite side
            PositionedDirectional(
              end: 16,
              bottom: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  AppSpacing.gapW4,
                  _RouteDot(color: AppColors.accentYellow),
                  AppSpacing.gapW4,
                  _RouteDot(color: Colors.white.withValues(alpha: 0.6)),
                  AppSpacing.gapW4,
                  _RouteDot(color: Colors.white.withValues(alpha: 0.3)),
                ],
              ),
            ),

            // 4. Visible Bus Artwork on opposite side (clean, high visibility, aspect-preserved)
            PositionedDirectional(
              end: -6,
              bottom: 8,
              child: AmomyBusIcon(
                width: 120,
                color: Colors.white,
                opacity: 0.85,
              ),
            ),

            // 5. Card Content Hierarchy
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 110, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pill Badge (Offer or Announcement)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isOffer
                          ? AppColors.accentYellow
                          : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOffer
                            ? AppColors.accentYellow
                            : Colors.white.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOffer ? AppIcons.ticket : AppIcons.info,
                          size: 11,
                          color: isOffer
                              ? AppColors.primaryDarker
                              : Colors.white,
                        ),
                        AppSpacing.gapW4,
                        Text(
                          isOffer ? l10n.offerBadge : l10n.announcementBadge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isOffer
                                ? AppColors.primaryDarker
                                : Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH8,

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.gapH4,

                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final Color color;

  const _RouteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
