import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/bus_seat_layout.dart';

/// Authentic vector-rendered top-down coach bus seat widget.
///
/// Geometric orientation:
/// The physical seat artwork itself is rotated 180 degrees so the
/// backrest/headrest faces the rear of the bus, and the cushion faces forward.
///
/// Text, passenger avatars, and status cues are NOT rotated (remain upright).
///
/// State representations:
/// - Available: Neutral slate grey + seat number centered on cushion.
/// - Selected: AMOMY Blue (#01589F) + luminous cyan contour + soft glow pulse.
/// - Booked Male: Deep dark navy blue seat + male avatar silhouette + seat number below.
/// - Booked Female: Rose/pink seat + female avatar silhouette + seat number below.
/// - Held: Warm amber/yellow seat + waiting timer cue + subtle breathing animation.
/// - Unconfigured: Translucent wireframe for safe debug preview.
class BusSeatVisual extends StatefulWidget {
  final String label;
  final SeatVisualState state;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const BusSeatVisual({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
    this.width = 40.0,
    this.height = 50.0,
  });

  @override
  State<BusSeatVisual> createState() => _BusSeatVisualState();
}

class _BusSeatVisualState extends State<BusSeatVisual>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  late AnimationController _heldPulseController;
  late Animation<double> _heldPulseAnimation;

  late AnimationController _avatarFadeController;
  late Animation<double> _avatarFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Selection & Tap Bounce Animation (1.0 -> 1.06 -> 1.0)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _bounceController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 2. Held / Waiting Seat Gentle Breathing Animation (1.0 -> 1.025 -> 1.0)
    _heldPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _heldPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heldPulseController, curve: Curves.easeInOut),
    );

    // 3. Occupant Avatar / Status Icon Smooth Fade-in
    // If the seat starts in an occupied/held/supervisor state, avatar/icon is visible immediately (value: 1.0)
    final initialHasAvatar =
        widget.state == SeatVisualState.bookedMale ||
        widget.state == SeatVisualState.bookedFemale ||
        widget.state == SeatVisualState.held ||
        widget.state == SeatVisualState.supervisorReserved;

    _avatarFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: initialHasAvatar ? 1.0 : 0.0,
    );
    _avatarFadeAnimation = CurvedAnimation(
      parent: _avatarFadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant BusSeatVisual oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state != widget.state) {
      if (widget.state == SeatVisualState.selected) {
        _triggerBounce();
      }

      final hadAvatar =
          oldWidget.state == SeatVisualState.bookedMale ||
          oldWidget.state == SeatVisualState.bookedFemale ||
          oldWidget.state == SeatVisualState.held ||
          oldWidget.state == SeatVisualState.supervisorReserved;
      final hasAvatar =
          widget.state == SeatVisualState.bookedMale ||
          widget.state == SeatVisualState.bookedFemale ||
          widget.state == SeatVisualState.held ||
          widget.state == SeatVisualState.supervisorReserved;

      final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

      if (!hadAvatar && hasAvatar) {
        if (disable) {
          _avatarFadeController.value = 1.0;
        } else {
          _avatarFadeController.forward(from: 0.0);
        }
      } else if (hadAvatar && !hasAvatar) {
        _avatarFadeController.value = 0.0;
      }

      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (!mounted) return;
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Held breathing pulse
    if (widget.state == SeatVisualState.held && !disable) {
      if (!_heldPulseController.isAnimating) {
        _heldPulseController.repeat(reverse: true);
      }
    } else {
      if (_heldPulseController.isAnimating) {
        _heldPulseController.stop();
        _heldPulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _heldPulseController.dispose();
    _avatarFadeController.dispose();
    super.dispose();
  }

  void _triggerBounce() {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disable) {
      _bounceController.forward(from: 0.0);
    }
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    _triggerBounce();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final isTappable =
        widget.state == SeatVisualState.available ||
        widget.state == SeatVisualState.selected;

    return Semantics(
      label:
          AppLocalizations.of(context)?.seatNumberLabel(widget.label) ??
          'Seat ${widget.label}',
      button: isTappable,
      enabled: isTappable,
      selected: widget.state == SeatVisualState.selected,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bounceAnimation,
          _heldPulseAnimation,
          _avatarFadeAnimation,
        ]),
        builder: (context, _) {
          final bounceScale = _bounceController.isAnimating
              ? _bounceAnimation.value
              : 1.0;
          final heldScale =
              (widget.state == SeatVisualState.held &&
                  _heldPulseController.isAnimating)
              ? (1.0 + _heldPulseAnimation.value * 0.025)
              : 1.0;
          final totalScale = bounceScale * heldScale;

          return Transform.scale(
            scale: totalScale,
            child: InkWell(
              onTap: isTappable ? _handleTap : null,
              borderRadius: BorderRadius.circular(10),
              splashColor: AppColors.primary.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              child: Container(
                width: widget.width,
                height: widget.height,
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _RealisticCoachSeatPainter(
                    state: widget.state,
                    label: widget.label,
                    heldPulse: _heldPulseAnimation.value,
                    avatarOpacity: _avatarFadeAnimation.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom vector painter rendering the top-down coach passenger seat.
///
/// Seat geometry is rotated 180° so backrest faces the rear of the bus.
/// Text, avatars, and status icons remain upright and readable.
class _RealisticCoachSeatPainter extends CustomPainter {
  final SeatVisualState state;
  final String label;
  final double heldPulse;
  final double avatarOpacity;

  const _RealisticCoachSeatPainter({
    required this.state,
    required this.label,
    this.heldPulse = 0.0,
    this.avatarOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final style = _resolveCoachStyle(state);

    // =========================================================================
    // 0. SEAT OUTER GLOW & AMBIENT SHADOW
    // =========================================================================
    if (state == SeatVisualState.selected) {
      // Soft cyan outer glow for selected seat
      final glowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      final glowRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 2.0, w - 1.0, h - 3.0),
        const Radius.circular(8.0),
      );
      canvas.drawRRect(glowRRect, glowPaint);
    } else if (state == SeatVisualState.held) {
      // Subtle pulsing amber glow for held seat
      final heldGlowAlpha = (0.22 + heldPulse * 0.18).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: heldGlowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
      final glowRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 2.0, w - 1.0, h - 3.0),
        const Radius.circular(8.0),
      );
      canvas.drawRRect(glowRRect, glowPaint);
    }

    // =========================================================================
    // PHYSICAL SEAT ARTWORK
    //
    // Rotate ONLY the physical chair geometry 180 degrees.
    // =========================================================================
    canvas.save();
    canvas.translate(w, h);
    canvas.rotate(math.pi);

    // 1. Drop Shadow
    if (state != SeatVisualState.unconfigured) {
      final shadowPaint = Paint()
        ..color = style.shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);

      final shadowRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 3.0, w - 3.0, h - 4.0),
        const Radius.circular(7.0),
      );
      canvas.drawRRect(shadowRRect, shadowPaint);
    }

    // 2. Mini Armrests (Along the cushion sides)
    final armrestPaint = Paint()
      ..color = style.armrestColor
      ..style = PaintingStyle.fill;
    final armrestStroke = Paint()
      ..color = style.borderColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.4, h * 0.38, 2.2, h * 0.44),
      const Radius.circular(1.1),
    );
    canvas.drawRRect(leftArm, armrestPaint);
    canvas.drawRRect(leftArm, armrestStroke);

    final rightArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - 2.6, h * 0.38, 2.2, h * 0.44),
      const Radius.circular(1.1),
    );
    canvas.drawRRect(rightArm, armrestPaint);
    canvas.drawRRect(rightArm, armrestStroke);

    // 3. Backrest Body (Spans top ~30% in local coordinates)
    final backrestRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.5, 4.0, w - 5.0, h * 0.32),
      const Radius.circular(6.0),
    );
    final backrestPaint = Paint()
      ..color = style.backrestColor
      ..style = PaintingStyle.fill;
    final backrestStroke = Paint()
      ..color = style.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.borderWidth;

    canvas.drawRRect(backrestRect, backrestPaint);
    canvas.drawRRect(backrestRect, backrestStroke);

    // 4. Contoured Headrest Pill (Mounted on top center)
    final headrestRect = RRect.fromRectAndRadius(
      Rect.fromLTWH((w - w * 0.66) / 2, 1.2, w * 0.66, h * 0.16),
      const Radius.circular(4.0),
    );
    final headrestPaint = Paint()
      ..color = style.headrestColor
      ..style = PaintingStyle.fill;
    final headrestStroke = Paint()
      ..color = style.headrestBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(headrestRect, headrestPaint);
    canvas.drawRRect(headrestRect, headrestStroke);

    // 5. Seat Cushion (Bottom ~60% in local coordinates)
    final cushionTop = h * 0.36;
    final cushionHeight = h - cushionTop - 2.0;

    final cushionRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.2, cushionTop, w - 6.4, cushionHeight),
      const Radius.circular(6.5),
    );
    final cushionPaint = Paint()
      ..color = style.cushionColor
      ..style = PaintingStyle.fill;
    final cushionStroke = Paint()
      ..color = style.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.borderWidth;

    canvas.drawRRect(cushionRect, cushionPaint);
    canvas.drawRRect(cushionRect, cushionStroke);

    // 6. Ergonomic Side Bolsters inside cushion
    final bolsterPaint = Paint()
      ..color = style.bolsterColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4.0, cushionTop + 2.0, 3.8, cushionHeight - 5.0),
        const Radius.circular(2.5),
      ),
      bolsterPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w - 7.8, cushionTop + 2.0, 3.8, cushionHeight - 5.0),
        const Radius.circular(2.5),
      ),
      bolsterPaint,
    );

    // 7. Center Cushion Insert
    final centerCushionRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8.5, cushionTop + 2.0, w - 17.0, cushionHeight - 5.0),
      const Radius.circular(4.0),
    );
    canvas.drawRRect(
      centerCushionRect,
      Paint()..color = style.centerCushionColor,
    );

    // 8. Fabric Stitch Seam
    final seamPaint = Paint()
      ..color = style.seamColor
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(9.0, cushionTop + cushionHeight * 0.44),
      Offset(w - 9.0, cushionTop + cushionHeight * 0.44),
      seamPaint,
    );

    canvas.restore();

    // =========================================================================
    // RESTORE NORMAL ORIENTATION (Upright text, avatars, and cues)
    // =========================================================================

    final isOccupied =
        state == SeatVisualState.bookedMale ||
        state == SeatVisualState.bookedFemale ||
        state == SeatVisualState.held ||
        state == SeatVisualState.supervisorReserved;

    // 9. Occupant Avatar / Status Cue in the UPPER part of the seat
    if (isOccupied && avatarOpacity > 0.0) {
      final double avatarCY = 13.5;

      if (state == SeatVisualState.bookedMale) {
        final maleColor = const Color(
          0xFF38BDF8,
        ).withValues(alpha: avatarOpacity.clamp(0.0, 1.0));
        _drawMaleAvatar(canvas, w * 0.5, avatarCY, maleColor);
      } else if (state == SeatVisualState.bookedFemale) {
        final femaleColor = Colors.white.withValues(
          alpha: avatarOpacity.clamp(0.0, 1.0),
        );
        _drawFemaleAvatar(canvas, w * 0.5, avatarCY, femaleColor);
      } else if (state == SeatVisualState.held) {
        final heldColor = Colors.white.withValues(
          alpha: avatarOpacity.clamp(0.0, 1.0),
        );
        _drawClockCue(canvas, w * 0.5, avatarCY, heldColor);
      } else if (state == SeatVisualState.supervisorReserved) {
        final lockColor = const Color(
          0xFF94A3B8,
        ).withValues(alpha: avatarOpacity.clamp(0.0, 1.0));
        _drawLockCue(canvas, w * 0.5, avatarCY, lockColor);
      }
    }

    // 10. Seat Number Placement
    // - AVAILABLE / SELECTED: Centered nicely on the cushion surface (y: ~10 to 24).
    // - OCCUPIED / HELD / SUPERVISOR: Positioned in the lower part (y: ~27.5), cleanly below the icon/avatar.
    if (label.isNotEmpty && state != SeatVisualState.unconfigured) {
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: style.textColor,
          fontSize: isOccupied ? 9.5 : 12.0,
          fontWeight: isOccupied ? FontWeight.w800 : FontWeight.w900,
          letterSpacing: -0.2,
          fontFamily: 'Inter',
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w - 8);

      // Target vertical positioning
      final double targetY = isOccupied
          ? 27.5
          : 17.0 - (textPainter.height / 2);

      final textOffset = Offset((w - textPainter.width) / 2, targetY);
      textPainter.paint(canvas, textOffset);
    }
  }

  // ===========================================================================
  // SUPERVISOR LOCK CUE (Vector-drawn compact padlock)
  // ===========================================================================
  void _drawLockCue(Canvas canvas, double cx, double cy, Color color) {
    final shacklePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Shackle arc: arching over body
    final shacklePath = Path()
      ..moveTo(cx - 2.6, cy - 1.2)
      ..lineTo(cx - 2.6, cy - 3.4)
      ..arcToPoint(
        Offset(cx + 2.6, cy - 3.4),
        radius: const Radius.circular(2.6),
        clockwise: true,
      )
      ..lineTo(cx + 2.6, cy - 1.2);
    canvas.drawPath(shacklePath, shacklePaint);

    // Padlock body (rounded rectangle)
    final lockBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 1.2), width: 7.2, height: 5.6),
      const Radius.circular(1.6),
    );
    canvas.drawRRect(lockBody, bodyPaint);

    // Subtle keyhole dot inside padlock body
    final keyholePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + 0.9), 0.75, keyholePaint);
  }

  // ===========================================================================
  // MALE AVATAR (Top-down head + shoulders)
  // ===========================================================================
  void _drawMaleAvatar(Canvas canvas, double cx, double cy, Color color) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Head circle
    canvas.drawCircle(Offset(cx, cy - 5.0), 2.8, fillPaint);

    // Rounded shoulders/torso arc
    final shoulderPath = Path()
      ..moveTo(cx - 6.0, cy + 4.5)
      ..quadraticBezierTo(cx - 4.5, cy - 1.0, cx, cy - 1.0)
      ..quadraticBezierTo(cx + 4.5, cy - 1.0, cx + 6.0, cy + 4.5);
    canvas.drawPath(shoulderPath, strokePaint);
  }

  // ===========================================================================
  // FEMALE AVATAR (Top-down head with feminine hair silhouette + flared dress)
  // ===========================================================================
  void _drawFemaleAvatar(Canvas canvas, double cx, double cy, Color color) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Head circle
    canvas.drawCircle(Offset(cx, cy - 4.8), 2.2, fillPaint);

    // 2. Distinctive feminine hair locks framing head and cascading past ears
    final hairPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final hairPath = Path()
      ..moveTo(cx - 3.7, cy - 1.5)
      ..quadraticBezierTo(cx - 4.6, cy - 4.6, cx - 2.0, cy - 7.4)
      ..quadraticBezierTo(cx, cy - 8.1, cx + 2.0, cy - 7.4)
      ..quadraticBezierTo(cx + 4.6, cy - 4.6, cx + 3.7, cy - 1.5);
    canvas.drawPath(hairPath, hairPaint);

    // 3. Stylized feminine dress with tapered waist and flared A-line skirt
    final dressPath = Path()
      ..moveTo(cx - 2.8, cy - 0.6) // Left shoulder
      ..quadraticBezierTo(
        cx - 1.8,
        cy + 1.2,
        cx - 5.8,
        cy + 4.6,
      ) // Tapered waist to flared left hem
      ..quadraticBezierTo(
        cx,
        cy + 5.4,
        cx + 5.8,
        cy + 4.6,
      ) // Gently curved bottom hem
      ..quadraticBezierTo(
        cx + 1.8,
        cy + 1.2,
        cx + 2.8,
        cy - 0.6,
      ) // Flared right hem to waist to shoulder
      ..quadraticBezierTo(cx, cy - 1.2, cx - 2.8, cy - 0.6) // Curved neckline
      ..close();
    canvas.drawPath(dressPath, fillPaint);
  }

  // ===========================================================================
  // HELD / WAITING TIMER CLOCK
  // ===========================================================================
  void _drawClockCue(Canvas canvas, double cx, double cy, Color color) {
    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final handPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Outer clock dial
    canvas.drawCircle(Offset(cx, cy - 0.5), 4.2, rimPaint);

    // Clock hour and minute hands
    canvas.drawLine(Offset(cx, cy - 0.5), Offset(cx, cy - 3.2), handPaint);
    canvas.drawLine(
      Offset(cx, cy - 0.5),
      Offset(cx + 1.8, cy - 0.5),
      handPaint,
    );
  }

  // ===========================================================================
  // SEAT STATE TOKENS
  // ===========================================================================
  _CoachSeatStyle _resolveCoachStyle(SeatVisualState state) {
    switch (state) {
      // -----------------------------------------------------------------------
      // SELECTED: AMOMY Blue (#01589F) with vibrant cyan contour & glow
      // -----------------------------------------------------------------------
      case SeatVisualState.selected:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFF01589F),
          headrestColor: const Color(0xFF003D73),
          headrestBorderColor: const Color(0xFF38BDF8),
          cushionColor: const Color(0xFF026CBF),
          centerCushionColor: const Color(0xFF01589F),
          bolsterColor: const Color(0xFF0A4E8A),
          armrestColor: const Color(0xFF00355F),
          borderColor: const Color(0xFF38BDF8),
          borderWidth: 2.2,
          seamColor: const Color(0xFF38BDF8).withValues(alpha: 0.55),
          textColor: Colors.white,
          shadowColor: const Color(0xFF01589F).withValues(alpha: 0.45),
        );

      // -----------------------------------------------------------------------
      // AVAILABLE: Neutral cool slate grey upholstery
      // -----------------------------------------------------------------------
      case SeatVisualState.available:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFF475569),
          headrestColor: const Color(0xFF64748B),
          headrestBorderColor: const Color(0xFF94A3B8),
          cushionColor: const Color(0xFF334155),
          centerCushionColor: const Color(0xFF2B384A),
          bolsterColor: const Color(0xFF475569),
          armrestColor: const Color(0xFF1E293B),
          borderColor: const Color(0xFF64748B),
          borderWidth: 1.2,
          seamColor: const Color(0xFF94A3B8).withValues(alpha: 0.25),
          textColor: Colors.white,
          shadowColor: Colors.black.withValues(alpha: 0.25),
        );

      // -----------------------------------------------------------------------
      // BOOKED MALE: Deep midnight dark navy blue upholstery (distinct from selected AMOMY blue)
      // -----------------------------------------------------------------------
      case SeatVisualState.bookedMale:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFF23476C),
          headrestColor: const Color(0xFF193550),
          headrestBorderColor: const Color(0xFF2F5D8A),
          cushionColor: const Color(0xFF1F4265),
          centerCushionColor: const Color(0xFF17324D),
          bolsterColor: const Color(0xFF23476C),
          armrestColor: const Color(0xFF12283E),
          borderColor: const Color(0xFF2F5D8A),
          borderWidth: 1.2,
          seamColor: const Color(0xFF5E7FA3).withValues(alpha: 0.38),
          textColor: const Color(0xFFF1F5F9),
          shadowColor: const Color(0xFF102338).withValues(alpha: 0.32),
        );
      // -----------------------------------------------------------------------
      // BOOKED FEMALE: Rose/pink upholstery with female avatar
      // -----------------------------------------------------------------------
      case SeatVisualState.bookedFemale:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFFE11D48),
          headrestColor: const Color(0xFFBE123C),
          headrestBorderColor: const Color(0xFFFDA4AF),
          cushionColor: const Color(0xFF9F1239),
          centerCushionColor: const Color(0xFF881337),
          bolsterColor: const Color(0xFFBE123C),
          armrestColor: const Color(0xFF881337),
          borderColor: const Color(0xFFFB7185),
          borderWidth: 1.3,
          seamColor: const Color(0xFFFB7185).withValues(alpha: 0.30),
          textColor: Colors.white,
          shadowColor: const Color(0xFFE11D48).withValues(alpha: 0.35),
        );

      // -----------------------------------------------------------------------
      // HELD / WAITING: Warm amber/yellow upholstery with timer cue
      // -----------------------------------------------------------------------
      case SeatVisualState.held:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFFD97706),
          headrestColor: const Color(0xFFB45309),
          headrestBorderColor: const Color(0xFFFDE68A),
          cushionColor: const Color(0xFFB45309),
          centerCushionColor: const Color(0xFF92400E),
          bolsterColor: const Color(0xFFD97706),
          armrestColor: const Color(0xFF78350F),
          borderColor: const Color(0xFFFBBF24),
          borderWidth: 1.4,
          seamColor: const Color(0xFFFDE68A).withValues(alpha: 0.35),
          textColor: const Color(0xFFFEF3C7),
          shadowColor: const Color(0xFFD97706).withValues(alpha: 0.35),
        );

      // -----------------------------------------------------------------------
      // SUPERVISOR RESERVED: Muted dark slate / indigo reserved upholstery with lock cue
      // -----------------------------------------------------------------------
      case SeatVisualState.supervisorReserved:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFF1E293B),
          headrestColor: const Color(0xFF0F172A),
          headrestBorderColor: const Color(0xFF334155),
          cushionColor: const Color(0xFF1E293B),
          centerCushionColor: const Color(0xFF141E30),
          bolsterColor: const Color(0xFF0F172A),
          armrestColor: const Color(0xFF0B1120),
          borderColor: const Color(0xFF475569),
          borderWidth: 1.2,
          seamColor: const Color(0xFF334155).withValues(alpha: 0.30),
          textColor: const Color(0xFF94A3B8),
          shadowColor: Colors.black.withValues(alpha: 0.30),
        );

      // -----------------------------------------------------------------------
      // UNAVAILABLE
      // -----------------------------------------------------------------------
      case SeatVisualState.unavailable:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
          headrestColor: const Color(0xFF0F172A),
          headrestBorderColor: const Color(0xFF334155),
          cushionColor: const Color(0xFF0F172A).withValues(alpha: 0.7),
          centerCushionColor: const Color(0xFF0A0F1D),
          bolsterColor: const Color(0xFF1E293B),
          armrestColor: const Color(0xFF334155),
          borderColor: const Color(0xFF334155),
          borderWidth: 1.0,
          seamColor: Colors.transparent,
          textColor: const Color(0xFF64748B),
          shadowColor: Colors.transparent,
        );

      // -----------------------------------------------------------------------
      // UNCONFIGURED DEBUG PREVIEW
      // -----------------------------------------------------------------------
      case SeatVisualState.unconfigured:
        return _CoachSeatStyle(
          backrestColor: const Color(0xFF1E293B).withValues(alpha: 0.3),
          headrestColor: const Color(0xFF0F172A).withValues(alpha: 0.3),
          headrestBorderColor: const Color(0xFF334155).withValues(alpha: 0.3),
          cushionColor: const Color(0xFF0F172A).withValues(alpha: 0.2),
          centerCushionColor: const Color(0xFF0A0F1D).withValues(alpha: 0.2),
          bolsterColor: const Color(0xFF1E293B).withValues(alpha: 0.2),
          armrestColor: const Color(0xFF334155).withValues(alpha: 0.3),
          borderColor: const Color(0xFF334155).withValues(alpha: 0.4),
          borderWidth: 0.8,
          seamColor: Colors.transparent,
          textColor: const Color(0xFF475569),
          shadowColor: Colors.transparent,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticCoachSeatPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.label != label ||
        oldDelegate.heldPulse != heldPulse ||
        oldDelegate.avatarOpacity != avatarOpacity;
  }
}

/// Visual tokens for one seat state.
class _CoachSeatStyle {
  final Color backrestColor;
  final Color headrestColor;
  final Color headrestBorderColor;
  final Color cushionColor;
  final Color centerCushionColor;
  final Color bolsterColor;
  final Color armrestColor;
  final Color borderColor;
  final double borderWidth;
  final Color seamColor;
  final Color textColor;
  final Color shadowColor;

  const _CoachSeatStyle({
    required this.backrestColor,
    required this.headrestColor,
    required this.headrestBorderColor,
    required this.cushionColor,
    required this.centerCushionColor,
    required this.bolsterColor,
    required this.armrestColor,
    required this.borderColor,
    required this.borderWidth,
    required this.seamColor,
    required this.textColor,
    required this.shadowColor,
  });
}
