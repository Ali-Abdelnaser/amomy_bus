import 'package:flutter/material.dart';

import 'app_animations.dart';

class AnimatedScreenEntry extends StatefulWidget {
  final Widget child;
  final Duration? delay;

  const AnimatedScreenEntry({super.key, required this.child, this.delay});

  @override
  State<AnimatedScreenEntry> createState() => _AnimatedScreenEntryState();
}

class _AnimatedScreenEntryState extends State<AnimatedScreenEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

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
      begin: reduceMotion ? Offset.zero : AppAnimations.screenEntryOffset,
      end: Offset.zero,
    ).animate(curve);

    if (_controller.status == AnimationStatus.dismissed) {
      final delay = reduceMotion ? null : widget.delay;
      if (delay == null || delay == Duration.zero) {
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
        child: widget.child,
      ),
    );
  }
}
