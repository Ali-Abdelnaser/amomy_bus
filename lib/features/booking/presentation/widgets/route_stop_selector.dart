import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/entities/booking_entities.dart';

/// Connected "Your Route" component with FROM (boarding) and TO (destination) stops,
/// vertical dashed transit connector, disambiguated localities, dynamic fare badge,
/// and full-width edge-to-edge modal bottom sheets.
class RouteStopSelector extends StatelessWidget {
  final RouteStop? selectedOrigin;
  final RouteStop? selectedDestination;
  final List<RouteStop> originStops;
  final List<RouteStop> destinationStops;
  final ValueChanged<RouteStop> onOriginSelected;
  final ValueChanged<RouteStop> onDestinationSelected;

  const RouteStopSelector({
    super.key,
    required this.selectedOrigin,
    required this.selectedDestination,
    required this.originStops,
    required this.destinationStops,
    required this.onOriginSelected,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // 1. FROM (Boarding Stop) Row
            _RouteStopField(
              isOrigin: true,
              label: isAr ? 'من' : 'From',
              placeholder: isAr ? 'اختر محطة الركوب' : 'Select boarding stop',
              stop: selectedOrigin,
              locale: locale,
              showFare: true,
              onTap: () => openStopPickerSheet(
                context: context,
                isOrigin: true,
                title: isAr ? 'اختر محطة الركوب' : 'Select boarding stop',
                helperText: isAr
                    ? 'حدد المحطة التي ستصعد منها للحافلة'
                    : 'Choose your pickup point along the route',
                stops: originStops,
                selectedStop: selectedOrigin,
                onSelected: onOriginSelected,
                locale: locale,
              ),
            ),

            // 2. Vertical Route Connector
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 13.0),
              child: Row(
                children: [
                  const _RouteDashedConnector(height: 18),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
            ),

            // 3. TO (Destination Stop) Row
            _RouteStopField(
              isOrigin: false,
              label: isAr ? 'إلى' : 'To',
              placeholder: isAr ? 'اختر محطة النزول' : 'Select destination',
              stop: selectedDestination,
              locale: locale,
              showFare: false,
              onTap: () => openStopPickerSheet(
                context: context,
                isOrigin: false,
                title: isAr ? 'اختر محطة النزول' : 'Select destination',
                helperText: isAr
                    ? 'المحطات المتاحة بعد محطة الركوب'
                    : 'Valid drop-off stops downstream from your origin',
                stops: destinationStops,
                selectedStop: selectedDestination,
                onSelected: onDestinationSelected,
                locale: locale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void openStopPickerSheet({
    required BuildContext context,
    required bool isOrigin,
    required String title,
    required String helperText,
    required List<RouteStop> stops,
    required RouteStop? selectedStop,
    required ValueChanged<RouteStop> onSelected,
    required String locale,
    bool showFare = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (ctx) {
        return _StopPickerModalSheet(
          isOrigin: isOrigin,
          title: title,
          helperText: helperText,
          stops: stops,
          selectedStop: selectedStop,
          onSelected: onSelected,
          locale: locale,
          showFare: showFare,
        );
      },
    );
  }
}

/// Interactive row for From or To in the connected route card.
class _RouteStopField extends StatelessWidget {
  final bool isOrigin;
  final String label;
  final String placeholder;
  final RouteStop? stop;
  final String locale;
  final bool showFare;
  final VoidCallback onTap;

  const _RouteStopField({
    required this.isOrigin,
    required this.label,
    required this.placeholder,
    required this.stop,
    required this.locale,
    required this.showFare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = locale.startsWith('ar');
    final pinColor = isOrigin ? AppColors.primary : const Color(0xFFD49B00);
    final pinBg = isOrigin
        ? AppColors.primary.withValues(alpha: 0.10)
        : const Color(0xFFFFC928).withValues(alpha: 0.18);
    final pinBorder = isOrigin
        ? AppColors.primary.withValues(alpha: 0.25)
        : const Color(0xFFD49B00).withValues(alpha: 0.30);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pin Icon Circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: pinBg,
                shape: BoxShape.circle,
                border: Border.all(color: pinBorder, width: 1.2),
              ),
              child: Icon(
                isOrigin
                    ? Icons.my_location_rounded
                    : Icons.location_on_rounded,
                size: 15,
                color: pinColor,
              ),
            ),
            const SizedBox(width: 12),

            // Stop Name + Locality (with disambiguation)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (stop != null) ...[
                    Text(
                      stop!.stopName(locale),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stop!.locality(locale).isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        stop!.locality(locale),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else ...[
                    Text(
                      placeholder,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Optional Boarding Fare Badge
            if (showFare && stop != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  isAr
                      ? '${stop!.farePoints.toInt()} نقطة'
                      : '${stop!.farePoints.toInt()} pts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Chevron Indicator
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle vertical dashed transit line between From and To pins.
class _RouteDashedConnector extends StatelessWidget {
  final double height;

  const _RouteDashedConnector({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      height: height,
      child: CustomPaint(
        size: Size(2, height),
        painter: _RouteDashedPainter(),
      ),
    );
  }
}

class _RouteDashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const dashHeight = 3.0;
    const dashSpace = 2.5;
    double startY = 0;

    final x = size.width / 2;
    while (startY < size.height) {
      final endY = (startY + dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Real full-width AMOMY Bottom Sheet for stop selection with instant search and fare display.
class _StopPickerModalSheet extends StatefulWidget {
  final bool isOrigin;
  final String title;
  final String helperText;
  final List<RouteStop> stops;
  final RouteStop? selectedStop;
  final ValueChanged<RouteStop> onSelected;
  final String locale;
  final bool showFare;

  const _StopPickerModalSheet({
    required this.isOrigin,
    required this.title,
    required this.helperText,
    required this.stops,
    required this.selectedStop,
    required this.onSelected,
    required this.locale,
    this.showFare = true,
  });

  @override
  State<_StopPickerModalSheet> createState() => _StopPickerModalSheetState();
}

class _StopPickerModalSheetState extends State<_StopPickerModalSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<RouteStop> _filteredStops = [];

  @override
  void initState() {
    super.initState();
    _filteredStops = widget.stops;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredStops = widget.stops);
      return;
    }

    setState(() {
      _filteredStops = widget.stops.where((s) {
        final arName = s.stopNameAr.toLowerCase();
        final enName = (s.stopNameEn ?? '').toLowerCase();
        final arLoc = s.localityAr.toLowerCase();
        final enLoc = (s.localityEn ?? '').toLowerCase();

        return arName.contains(query) ||
            enName.contains(query) ||
            arLoc.contains(query) ||
            enLoc.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.locale.startsWith('ar');
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final bottomSafe = mediaQuery.padding.bottom;
    final availableHeight = mediaQuery.size.height - keyboardInset;
    final maxHeight = keyboardInset > 0
        ? (availableHeight * 0.92).clamp(240.0, availableHeight)
        : (mediaQuery.size.height * 0.82);
    final listBottomPadding = keyboardInset > 0
        ? 12.0
        : math.max(bottomSafe, 16.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Single Central Drag Handle
              const SizedBox(height: 12),
              const AmomyDragHandle(),
              const SizedBox(height: 14),

              // 2. Header (Title + Close Button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF101828),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.helperText,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? 'ابحث باسم المحطة أو المنطقة...'
                          : 'Search stop name or locality...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        AppIcons.search,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 4. Scrollable Stops List
              Flexible(
                child: _filteredStops.isEmpty
                    ? Padding(
                        padding: EdgeInsets.only(
                          top: 36,
                          left: 24,
                          right: 24,
                          bottom: 36 + (keyboardInset > 0 ? 0 : bottomSafe),
                        ),
                        child: Center(
                          child: Text(
                            isAr
                                ? 'لا توجد محطات مطابقة للبحث'
                                : 'No matching stops found',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: listBottomPadding,
                        ),
                        itemCount: _filteredStops.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 64,
                          endIndent: 20,
                          color: Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final stop = _filteredStops[index];
                          final isSelected =
                              widget.selectedStop?.routeStopId ==
                                  stop.routeStopId;

                          return InkWell(
                            onTap: () {
                              widget.onSelected(stop);
                              Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  // Selected Radio / Pin Icon
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.12,
                                            )
                                          : const Color(0xFFF8FAFC),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFCBD5E1),
                                        width: isSelected ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_rounded
                                          : (widget.isOrigin
                                              ? Icons.my_location_rounded
                                              : Icons.location_on_rounded),
                                      size: 16,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Stop Name + Disambiguated Locality
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          stop.stopName(widget.locale),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w700,
                                            color: isSelected
                                                ? AppColors.primary
                                                : const Color(0xFF101828),
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (stop
                                            .locality(widget.locale)
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            stop.locality(widget.locale),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                   // Boarding Stop Fare Badge (Origin only)
                                   if (widget.showFare &&
                                       widget.isOrigin &&
                                       stop.farePoints > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isAr
                                            ? '${stop.farePoints.toInt()} نقطة'
                                            : '${stop.farePoints.toInt()} pts',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
