import 'package:flutter/material.dart';
import '../../domain/entities/booking_entities.dart';
import 'professional_bus_seat_map.dart';

/// Interactive top-view 28-seat physical bus map widget with smooth entrance animation.
///
/// Features:
/// - Entrance animation: bus drives/slides up from below the viewport (Offset(0, 0.75))
///   and smoothly settles into place with a subtle 5px overshoot over 850ms.
/// - Single-play lifecycle: animates once per entry into the seat map step.
///   Does NOT replay on seat selections, countdown ticks, or state updates.
/// - Reduced motion: immediately renders at final position if disableAnimations is true.
/// - High performance: whole-bus [SlideTransition] avoids re-rendering child seat painters.
/// - Geometry preserved: 100% preserves authoritative 28-seat layout geometry.
class BusSeatMapWidget extends StatefulWidget {
  final List<TripSeat> seats;
  final TripSeat? selectedSeat;
  final ValueChanged<TripSeat> onSeatTap;

  const BusSeatMapWidget({
    super.key,
    required this.seats,
    required this.selectedSeat,
    required this.onSeatTap,
  });

  @override
  State<BusSeatMapWidget> createState() => _BusSeatMapWidgetState();
}

class _BusSeatMapWidgetState extends State<BusSeatMapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _opacityAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // Sequence: 85% easeOutCubic upward drive with subtle 5px overshoot, then 15% settle
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.0, 0.75),
          end: const Offset(0.0, -0.008), // ~5px subtle overshoot
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 85,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.0, -0.008),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 15,
      ),
    ]).animate(_entranceController);

    _opacityAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disable) {
        _entranceController.value = 1.0;
      } else {
        _entranceController.forward();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfessionalBusSeatMap(
              seats: widget.seats,
              selectedSeat: widget.selectedSeat,
              onSeatTap: widget.onSeatTap,
            ),
          ],
        ),
      ),
    );
  }
}
