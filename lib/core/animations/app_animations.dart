import 'package:flutter/material.dart';

/// Central animation tokens for route transitions and screen entrances.
abstract final class AppAnimations {
  static const Duration routeTransitionDuration = Duration(milliseconds: 240);
  static const Duration routeReverseTransitionDuration = Duration(
    milliseconds: 180,
  );
  static const Duration reducedMotionRouteDuration = Duration(milliseconds: 80);

  static const Duration screenEntryDuration = Duration(milliseconds: 340);
  static const Duration reducedMotionScreenEntryDuration = Duration(
    milliseconds: 80,
  );

  static const Curve routeCurve = Curves.easeOutCubic;
  static const Curve screenEntryCurve = Curves.easeOutCubic;

  static const Offset screenEntryOffset = Offset(0, 0.04);

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

extension AppAnimationExtensions on Widget {
  Widget appFadeIn({Duration delay = Duration.zero}) {
    return _AppEntranceEffect(delay: delay, offset: Offset.zero, child: this);
  }

  Widget appSlideUp({Duration delay = Duration.zero}) {
    return _AppEntranceEffect(
      delay: delay,
      offset: AppAnimations.screenEntryOffset,
      child: this,
    );
  }

  Widget appScaleIn({Duration delay = Duration.zero}) {
    return _AppEntranceEffect(
      delay: delay,
      offset: Offset.zero,
      beginScale: 0.96,
      child: this,
    );
  }
}

class _AppEntranceEffect extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;
  final double beginScale;

  const _AppEntranceEffect({
    required this.child,
    required this.delay,
    required this.offset,
    this.beginScale = 1,
  });

  @override
  State<_AppEntranceEffect> createState() => _AppEntranceEffectState();
}

class _AppEntranceEffectState extends State<_AppEntranceEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.screenEntryDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppAnimations.reduceMotion(context);
    _controller.duration = reduceMotion
        ? AppAnimations.reducedMotionScreenEntryDuration
        : AppAnimations.screenEntryDuration;

    final curve = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.screenEntryCurve,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: reduceMotion ? Offset.zero : widget.offset,
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(
      begin: reduceMotion ? 1 : widget.beginScale,
      end: 1,
    ).animate(curve);

    if (_controller.status == AnimationStatus.dismissed) {
      final delay = reduceMotion ? Duration.zero : widget.delay;
      if (delay == Duration.zero) {
        _controller.forward();
      } else {
        Future<void>.delayed(delay, () {
          if (mounted) _controller.forward();
        });
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        transformHitTests: false,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
