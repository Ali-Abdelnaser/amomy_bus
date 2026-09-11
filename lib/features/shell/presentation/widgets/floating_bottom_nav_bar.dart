import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'nav_svg_icon.dart';

/// Item definition for [FloatingBottomNavBar].
class FloatingNavItem {
  final NavSvgType svgType;
  final String label;

  const FloatingNavItem({
    required this.svgType,
    required this.label,
  });
}

/// A compact, luxury floating glass bottom navigation bar with an animated sliding pill.
///
/// Design characteristics:
/// - **Refined AMOMY Slate-Gray Glass**: Elegant translucent blue-gray/slate glass
///   background with real `BackdropFilter` and crisp contrast.
/// - **Sliding Pill Indicator**: A single solid AMOMY blue pill physically slides
///   horizontally across slots with a calm, gentle curve (`Curves.easeInOutCubic`).
/// - **Comfortable Pill Padding**: Active slot expands to ~35% of the bar width
///   giving generous inner padding around longer labels like "My Trips" and "الرئيسية".
/// - **Prominent Icons & Typography**: Larger vector icons (23.5px active, 22px inactive)
///   and clear 13px bold text.
/// - **Bilingual & RTL**: Uses [AnimatedPositionedDirectional] for natural right-to-left sliding in Arabic.
class FloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<FloatingNavItem> items;

  const FloatingBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final bottomMargin = bottomPadding > 0 ? bottomPadding + 8 : 16.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomMargin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(33),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              // Refined AMOMY translucent blue-gray/slate glass
              color: const Color(0xE8EEF2F6),
              borderRadius: BorderRadius.circular(33),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemCount = items.length;

                // 35% width for active tab gives comfortable inner padding for longer words like "My Trips".
                // Remaining 65% is split evenly among the other 3 inactive tabs (~21.67% each).
                const activeRatio = 0.35;
                final inactiveRatio =
                    itemCount > 1 ? (1.0 - activeRatio) / (itemCount - 1) : 1.0;

                final activeWidth = totalWidth * activeRatio;
                final inactiveWidth = totalWidth * inactiveRatio;

                final clampedIndex =
                    selectedIndex.clamp(0, itemCount > 0 ? itemCount - 1 : 0);
                final pillStart = clampedIndex * inactiveWidth;
                final pillWidth = (activeWidth - 4.0).clamp(0.0, totalWidth);

                return Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    // 1. Sliding Pill Background that physically travels between tabs
                    if (itemCount > 0)
                      AnimatedPositionedDirectional(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeInOutCubic,
                        start: pillStart + 2.0,
                        top: 3.0,
                        bottom: 3.0,
                        width: pillWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.38),
                                blurRadius: 14,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 2. Interactive Item Slots with animated widths
                    Row(
                      children: List.generate(itemCount, (index) {
                        final isSelected = selectedIndex == index;
                        final itemWidth =
                            isSelected ? activeWidth : inactiveWidth;

                        return AnimatedContainer(
                          key: ValueKey('floating_nav_item_$index'),
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeInOutCubic,
                          width: itemWidth,
                          child: _FloatingNavItemTile(
                            item: items[index],
                            isSelected: isSelected,
                            onTap: () => onItemSelected(index),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItemTile extends StatefulWidget {
  final FloatingNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloatingNavItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FloatingNavItemTile> createState() => _FloatingNavItemTileState();
}

class _FloatingNavItemTileState extends State<_FloatingNavItemTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curve;

  static const Color _inactiveIconColor = Color(0xFF5A6E85);
  static const Color _inactiveLabelColor = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _FloatingNavItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: widget.isSelected,
      label: widget.item.label,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final t = _curve.value;

            return Center(
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inactive Layout: Vertical Column (Icon top, Label below)
                    // Calmly fades out as t goes 0.0 -> 0.7
                    Opacity(
                      opacity: (1.0 - (t * 1.4)).clamp(0.0, 1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NavSvgIcon(
                            type: widget.item.svgType,
                            color: _inactiveIconColor,
                            size: 22,
                          ),
                          const SizedBox(height: 2.5),
                          Text(
                            widget.item.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _inactiveLabelColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),

                    // Active Layout: Horizontal Pill (Icon + Label side-by-side with generous inner padding)
                    // Calmly fades and glides in as t goes 0.25 -> 1.0
                    Opacity(
                      opacity: ((t - 0.25) / 0.75).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NavSvgIcon(
                              type: widget.item.svgType,
                              color: Colors.white,
                              size: 23.5,
                            ),
                            const SizedBox(width: 6.5),
                            Flexible(
                              child: Text(
                                widget.item.label,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
