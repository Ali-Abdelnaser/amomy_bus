import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/announcement.dart';

/// Swipeable & auto-scrolling announcements carousel displaying official visual banners.
/// Displays announcement_1.png, announcement_2.png, announcement_3.png in exact sequential order.
class HomeAnnouncementsSection extends StatefulWidget {
  final List<Announcement>? announcements;
  final List<String> banners;

  const HomeAnnouncementsSection({
    super.key,
    this.announcements,
    this.banners = AppAssets.announcementBanners,
  });

  @override
  State<HomeAnnouncementsSection> createState() =>
      _HomeAnnouncementsSectionState();
}

class _HomeAnnouncementsSectionState extends State<HomeAnnouncementsSection> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  List<String> get _activeBanners =>
      widget.banners.isNotEmpty ? widget.banners : AppAssets.announcementBanners;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant HomeAnnouncementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_activeBanners.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextIndex = (_currentPage + 1) % _activeBanners.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = _activeBanners;
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swipeable & Auto-scrolling 16:9 Banner Carousel
        AspectRatio(
          aspectRatio: 16 / 9,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                if (notification.dragDetails != null) {
                  // User started dragging, pause auto-scroll
                  _pauseAutoScroll();
                }
              } else if (notification is ScrollEndNotification) {
                // Drag ended, resume auto-scroll
                _startAutoScroll();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final bannerPath = banners[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFDCE7F3).withValues(alpha: 0.8),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF01589F).withValues(alpha: 0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.asset(
                      bannerPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Smooth Page Indicator (Only if more than 1 announcement)
        if (banners.length > 1) ...[
          AppSpacing.gapH10,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final isSelected = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 20 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentYellow
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
