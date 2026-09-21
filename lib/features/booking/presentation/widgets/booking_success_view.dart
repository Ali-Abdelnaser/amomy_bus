import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/booking_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/booking_cubit.dart';
import 'app_qr_ticket_widget.dart';

class BookingSuccessView extends StatefulWidget {
  final PassengerBooking? booking;
  final RoundTripConfirmation? bundleConfirmation;

  const BookingSuccessView({super.key, this.booking, this.bundleConfirmation})
    : assert(booking != null || bundleConfirmation != null);

  @override
  State<BookingSuccessView> createState() => _BookingSuccessViewState();
}

class _BookingSuccessViewState extends State<BookingSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final Animation<double> _fadeAnimation;
  AudioPlayer? _audioPlayer;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _controller.value = 1.0;
      } else {
        _playPrinterSound();
        _controller.forward();
      }
    });
  }

  void _playPrinterSound() {
    if (_soundPlayed) return;
    _soundPlayed = true;
    try {
      _audioPlayer ??= AudioPlayer();
      _audioPlayer?.setReleaseMode(ReleaseMode.release);
      _audioPlayer?.setVolume(0.35);
      _audioPlayer?.play(AssetSource('audio/printer_dispense.wav'));
    } catch (_) {
      // Audio playback failsafe — audio issues should never interrupt UI
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(
      context,
    ).languageCode.startsWith('ar');
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final isBundle = widget.bundleConfirmation != null;
    final bundle = widget.bundleConfirmation;

    return Container(
      color: const Color(0xFFF8FAFC), // Crisp paper background contrast
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s20,
            AppSpacing.s20,
            math.max(AppSpacing.s24, bottomInset + AppSpacing.s16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Animated success check & 2. Localized title & 3. Subtitle
              _ConfirmationHeader(
                title: isBundle
                    ? (isArabic
                          ? 'تم حجز الذهاب والعودة بنجاح'
                          : 'Round Trip Booked Successfully')
                    : l10n.bookingSuccessTitle,
                subtitle: isBundle
                    ? (isArabic
                          ? 'وفرت ${bundle!.discountPoints.toInt()} نقاط'
                          : 'Saved ${bundle!.discountPoints.toInt()} points')
                    : l10n.bookingSuccessSubtitle,
                savingsBadge: isBundle
                    ? '${isArabic ? "وفرت" : "Saved"} ${bundle!.discountPoints.toInt()} ${l10n.pointsUnit}'
                    : null,
              ),
              AppSpacing.gapH20,

              // 4. Stylized printer slot & 5. Animated emerging ticket
              _TicketPrinterSection(
                booking: widget.booking,
                bundle: bundle,
                isArabic: isArabic,
                animation: _animation,
                fadeAnimation: _fadeAnimation,
              ),
              AppSpacing.gapH24,

              // 6. My Trips & 7. Go to Home
              const _SuccessActions(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Redesigned bold confirmation badge with multi-layer pulsing rings and spring animation.
class _ConfirmationHeader extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String? savingsBadge;

  const _ConfirmationHeader({this.title, this.subtitle, this.savingsBadge});

  @override
  State<_ConfirmationHeader> createState() => _ConfirmationHeaderState();
}

class _ConfirmationHeaderState extends State<_ConfirmationHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkAnimController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseRingAnimation;
  late final Animation<double> _ringOpacityAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _pulseRingAnimation = Tween<double>(begin: 0.8, end: 1.35).animate(
      CurvedAnimation(
        parent: _checkAnimController,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOutQuad),
      ),
    );

    _ringOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _checkAnimController,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
      ),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _checkAnimController,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _checkAnimController.value = 1.0;
      } else {
        _checkAnimController.forward();
      }
    });
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        // Redesigned Animated Green Success Badge
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing shockwave ripple ring
              AnimatedBuilder(
                animation: _checkAnimController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseRingAnimation.value,
                    child: Opacity(
                      opacity: _ringOpacityAnimation.value,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Soft static ambient glow ring
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                ),
              ),

              // Spring-scaled vibrant emerald badge
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF34D399), // Emerald 400
                        Color(0xFF059669), // Emerald 600
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.38),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapH12,

        // Animated Headline & Subtitle
        SlideTransition(
          position: _textSlideAnimation,
          child: FadeTransition(
            opacity: _textFadeAnimation,
            child: Column(
              children: [
                Text(
                  widget.title ?? l10n.bookingSuccessTitle,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH4,
                Text(
                  widget.subtitle ?? l10n.bookingSuccessSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.savingsBadge != null
                        ? const Color(0xFF15803D)
                        : AppColors.textSecondary,
                    fontWeight: widget.savingsBadge != null
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.savingsBadge != null) ...[
                  AppSpacing.gapH8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF86EFAC),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.savingsBadge!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Round Trip compact 3-row summary for the ticket bottom area.
class _RoundTripTicketSummary extends StatelessWidget {
  final RoundTripConfirmation bundle;
  final bool isArabic;

  const _RoundTripTicketSummary({required this.bundle, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pointsUnit = l10n.pointsUnit;

    // 1. Authoritative bundle values
    final subtotal = bundle.subtotalPoints;
    final discountPercent = bundle.discountPercent;
    final discountPoints = bundle.discountPoints;

    // 2. Authoritative leg fares
    double outboundFare = 0;
    double returnFare = 0;

    try {
      final bookingState = context.read<BookingCubit>().state;
      final retOpt = bookingState.selectedReturnOption;
      final hold = bookingState.bundleHold;

      outboundFare = (retOpt != null && retOpt.outboundBaseFarePoints > 0)
          ? retOpt.outboundBaseFarePoints.toDouble()
          : ((hold != null && hold.outboundBaseFarePoints > 0)
                ? hold.outboundBaseFarePoints
                : (bookingState.selectedRouteStop?.farePoints ??
                      bookingState.selectedTrip?.farePoints ??
                      0));

      returnFare = (retOpt != null && retOpt.returnBaseFarePoints > 0)
          ? retOpt.returnBaseFarePoints.toDouble()
          : ((hold != null && hold.returnBaseFarePoints > 0)
                ? hold.returnBaseFarePoints
                : 0);
    } catch (_) {}

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ROW 1: Outbound + Return Leg Fares
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: isArabic ? 'ذهاب ' : 'Outbound ',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    TextSpan(
                      text: '${outboundFare.toInt()} $pointsUnit',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: isArabic ? 'عودة ' : 'Return ',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    TextSpan(
                      text: '${returnFare.toInt()} $pointsUnit',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ROW 2: Subtotal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'الإجمالي' : 'Subtotal',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${subtotal.toInt()} $pointsUnit',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // ROW 3: Discount + Savings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic
                      ? 'خصم ذهاب وعودة ${discountPercent.toInt()}%'
                      : 'Round Trip Discount ${discountPercent.toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0284C7),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isArabic
                        ? 'وفرت ${discountPoints.toInt()} نقاط'
                        : 'Saved ${discountPoints.toInt()} pts',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Printer output area + ticket emerging downwards with realistic receipt animation.
class _TicketPrinterSection extends StatelessWidget {
  final PassengerBooking? booking;
  final RoundTripConfirmation? bundle;
  final bool isArabic;
  final Animation<double> animation;
  final Animation<double> fadeAnimation;

  const _TicketPrinterSection({
    this.booking,
    this.bundle,
    required this.isArabic,
    required this.animation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxAvailableWidth = constraints.maxWidth;
        final ticketWidth = math.min(maxAvailableWidth, 340.0);
        final ticketHeight = ticketWidth * 633 / 444;
        final printerWidth = math.min(maxAvailableWidth, ticketWidth + 24.0);
        const slotY = 34.0; // Emergence point right below printer body aperture

        return Center(
          child: SizedBox(
            width: printerWidth,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Emerging ticket container (clipped at top so it emerges from slot)
                Padding(
                  padding: const EdgeInsets.only(top: slotY),
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final translateY = (1.0 - animation.value) * -80.0;
                        final opacity = fadeAnimation.value;
                        return Transform.translate(
                          offset: Offset(0, translateY),
                          child: Opacity(opacity: opacity, child: child),
                        );
                      },
                      child: SizedBox(
                        width: ticketWidth,
                        height: ticketHeight,
                        child: _BookingTicket(
                          booking: booking,
                          bundle: bundle,
                          isArabic: isArabic,
                        ),
                      ),
                    ),
                  ),
                ),

                // Enhanced printer head housing with "Amomy Bus"
                Positioned(
                  top: 0,
                  child: _PrinterSlot(
                    width: printerWidth,
                    slotWidth: ticketWidth,
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

/// Stylized digital printer head housing (taller profile, LED, Amomy Bus branding, and paper slot).
class _PrinterSlot extends StatelessWidget {
  final double width;
  final double slotWidth;

  const _PrinterSlot({required this.width, required this.slotWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 42.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
          bottom: Radius.circular(6),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E293B), // Slate 800
            Color(0xFF0F172A), // Slate 900
          ],
        ),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top subtle specular highlight edge
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            height: 1.0,
            child: Container(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            ),
          ),

          // Center Branding: LED indicator + "Amomy Bus"
          Positioned(
            top: 9,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Emerald Status LED
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Amomy Bus',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),

          // Output slot aperture at bottom
          Positioned(
            bottom: 3,
            child: Container(
              width: slotWidth * 0.95,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(2.5),
                border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Official SVG Ticket Card displaying QR code on top and 3 meta columns at bottom with paper depth.
class _BookingTicket extends StatelessWidget {
  final PassengerBooking? booking;
  final RoundTripConfirmation? bundle;
  final bool isArabic;

  const _BookingTicket({this.booking, this.bundle, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isRoundTrip = bundle != null;

    final departureTime = booking != null
        ? AppTimeFormatter.formatPassengerBooking(booking!, isArabic: isArabic)
        : '';
    final fare = booking != null
        ? '${booking!.farePoints.toInt()} ${l10n.pointsUnit}'
        : '';
    final qrData = booking?.qrToken ?? bundle?.bundleId ?? '';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, ticketConstraints) {
          final width = ticketConstraints.maxWidth;
          final height = ticketConstraints.maxHeight;
          final qrSize = (width * 0.72).clamp(200.0, 260.0);

          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
                bottom: Radius.circular(8),
              ),
              boxShadow: [
                // Soft ambient paper drop shadow for tactile depth
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Ticket SVG Background (renders vector outline + white fill)
                SvgPicture.asset(
                  'assets/images/booking_ticket.svg',
                  fit: BoxFit.fill,
                  matchTextDirection: false,
                ),

                // 2. Upper area: ONLY the QR code (large, centered)
                Positioned(
                  top: height * (32 / 633),
                  left: 0,
                  right: 0,
                  bottom: height * (175 / 633),
                  child: Center(
                    child: AppQrTicketWidget(data: qrData, size: qrSize),
                  ),
                ),

                // 3. Lower area below the QR
                if (isRoundTrip)
                  Positioned(
                    left: width * (28 / 444),
                    right: width * (28 / 444),
                    top: height * (482 / 633),
                    bottom: height * (18 / 633),
                    child: _RoundTripTicketSummary(
                      bundle: bundle!,
                      isArabic: isArabic,
                    ),
                  )
                else if (booking != null)
                  // Single Trip UNCHANGED: exactly 3 columns (TIME, SEAT, FEES)
                  Positioned(
                    left: width * (20 / 444),
                    right: width * (20 / 444),
                    top: height * (490 / 633),
                    bottom: height * (22 / 633),
                    child: Row(
                      children: [
                        _TicketValue(
                          label: l10n.bookingTicketTime,
                          value: departureTime,
                        ),
                        _TicketValue(
                          label: l10n.bookingTicketSeat,
                          value: booking!.seatNumber,
                        ),
                        _TicketValue(
                          label: l10n.bookingTicketFees,
                          value: fare,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TicketValue extends StatelessWidget {
  final String label;
  final String value;

  const _TicketValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH4,
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessActions extends StatelessWidget {
  const _SuccessActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.bookingSuccessMyTrips,
          icon: const Icon(AppIcons.bus, size: 18, color: Colors.white),
          height: 48,
          isFullWidth: true,
          onPressed: () => context.go(RoutePaths.trips),
        ),
        AppSpacing.gapH10,
        AppButton(
          label: l10n.bookingSuccessGoHome,
          icon: const Icon(AppIcons.home, size: 18),
          variant: ButtonVariant.outline,
          height: 48,
          isFullWidth: true,
          onPressed: () => context.go(RoutePaths.home),
        ),
      ],
    );
  }
}
