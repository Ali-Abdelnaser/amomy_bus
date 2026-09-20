import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Production AMOMY Bus Marker for interactive tracking maps.
///
/// Clean, stable circular transit marker:
/// - Primary AMOMY blue circular surface with 2.5px white border
/// - Centered clean Material bus icon (Icons.directions_bus_rounded)
/// - Soft radial pulse halo (2.2s live, 3.8s at stop)
/// - Reconnecting / stale state: amber warning ring, calm pulse
/// - Offline state: muted slate gray, no pulse
/// - QA Preview: tiny QA badge
/// - NO SVG, NO direction/heading rotation, NO tilted bus (north-up stability).
class AmomyBusMarker extends StatefulWidget {
  final int heading;
  final bool isMoving;
  final bool isStale;
  final bool isQaSimulated;
  final bool isAtStop;
  final double size;
  final VoidCallback? onTap;

  const AmomyBusMarker({
    super.key,
    this.heading = 0,
    this.isMoving = false,
    this.isStale = false,
    this.isQaSimulated = false,
    this.isAtStop = false,
    this.size = 46.0,
    this.onTap,
  });

  @override
  State<AmomyBusMarker> createState() => _AmomyBusMarkerState();
}

class _AmomyBusMarkerState extends State<AmomyBusMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isAtStop ? 3800 : 2200),
    );

    if (!widget.isStale) {
      _pulseController.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.28).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.10, end: 0.28).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AmomyBusMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStale) {
      if (_pulseController.isAnimating) _pulseController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (oldWidget.isAtStop != widget.isAtStop) {
        _pulseController.duration = Duration(
          milliseconds: widget.isAtStop ? 3800 : 2200,
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double markerDiameter = widget.size.clamp(40.0, 52.0);
    final double iconSize = markerDiameter * 0.52;

    // Visual colors based on state
    final Color surfaceColor;
    final Color borderColor;
    final Color haloColor;
    final Color iconColor = Colors.white;

    if (widget.isStale) {
      // Reconnecting / stale: amber ring, muted surface
      surfaceColor = const Color(0xFF475569);
      borderColor = const Color(0xFFF59E0B);
      haloColor = const Color(0xFFF59E0B);
    } else if (widget.isQaSimulated) {
      surfaceColor = const Color(0xFF4F46E5);
      borderColor = Colors.white;
      haloColor = const Color(0xFF6366F1);
    } else {
      // LIVE / AT STOP: AMOMY Primary Blue with crisp white border
      surfaceColor = AppColors.primary;
      borderColor = Colors.white;
      haloColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: markerDiameter + 16,
          height: markerDiameter + 16,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Soft radial pulse halo
              if (!widget.isStale)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final currentScale = _pulseAnimation.value;
                    final currentOpacity = _opacityAnimation.value;

                    return Transform.scale(
                      scale: currentScale,
                      child: Container(
                        width: markerDiameter + 12,
                        height: markerDiameter + 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              haloColor.withValues(alpha: currentOpacity),
                              haloColor.withValues(
                                alpha: currentOpacity * 0.35,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.25, 0.70, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // 2. Main Circular Bus Surface (High contrast on Alidade Smooth)
              Container(
                width: markerDiameter,
                height: markerDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor,
                  border: Border.all(color: borderColor, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: surfaceColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: iconColor,
                    size: iconSize,
                  ),
                ),
              ),

              // 3. Tiny QA indicator badge (only when simulated)
              if (widget.isQaSimulated)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Text(
                      'QA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
