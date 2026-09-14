import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/booking_entities.dart';
import 'booking_qr_ticket_card.dart';

/// Premium Booking Success View with realistic printing ticket animation.
///
/// Animation Sequence (Total 3100ms):
/// - 0.00–0.08: Printer wake-up & green checkmark animation (~250ms, status LED, micro warmup).
/// - 0.08–0.78: Ticket feed & subtle dispenser sound (~2170ms, smooth physical progress).
/// - 0.78–0.90: Ticket final exit / settle (~370ms, subtle vertical settle, audio stops).
/// - 0.90–1.00: Confirmation actions smoothly fade and slide in (~310ms).
class BookingSuccessView extends StatefulWidget {
  final PassengerBooking booking;

  const BookingSuccessView({
    super.key,
    required this.booking,
  });

  @override
  State<BookingSuccessView> createState() => _BookingSuccessViewState();
}

class _BookingSuccessViewState extends State<BookingSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  AudioPlayer? _audioPlayer;
  bool _soundStarted = false;
  bool _soundStopped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3100),
    );

    _controller.addListener(_handleAnimationTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  void _handleAnimationTick() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) return;

    final progress = _controller.value;
    if (!_soundStarted && progress >= 0.08 && progress < 0.78) {
      _soundStarted = true;
      _playPrinterSound();
    } else if (_soundStarted && !_soundStopped && progress >= 0.78) {
      _soundStopped = true;
      _stopPrinterSound();
    }
  }

  Future<void> _playPrinterSound() async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer?.setVolume(0.35);
      await _audioPlayer?.play(AssetSource('audio/printer_dispense.wav'));
    } catch (_) {
      // Audio failsafe: playback failure never blocks or interrupts the UI
    }
  }

  Future<void> _stopPrinterSound() async {
    try {
      await _audioPlayer?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.removeListener(_handleAnimationTick);
    _controller.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');

    final screenWidth = MediaQuery.sizeOf(context).width;
    final safeWidth = screenWidth > 0 ? screenWidth : 375.0;

    // Responsive portrait ticket dimensions (445 x 939)
    final ticketWidth = math.min(safeWidth - 48.0, 300.0).clamp(240.0, 300.0);
    final ticketHeight = ticketWidth *
        (BookingQrTicketSvgBackground.svgHeight /
            BookingQrTicketSvgBackground.svgWidth);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          // -------------------------------------------------------------------
          // SUCCESS CHECK ANIMATION (450–600ms / ~0.00 – 0.19)
          // -------------------------------------------------------------------
          final checkT = (progress / 0.18).clamp(0.0, 1.0);
          final checkScale = Curves.easeOutBack.transform(checkT);
          final effectiveScale = 0.75 + (0.25 * checkScale);
          final checkOpacity = Curves.easeOut.transform((progress / 0.12).clamp(0.0, 1.0));

          // -------------------------------------------------------------------
          // PHASE 1: Printer Wake-Up (0.00 – 0.08)
          // -------------------------------------------------------------------
          final slotGlow = (progress < 0.78)
              ? (math.sin(progress * math.pi * 3).abs() * 0.7)
              : 0.0;

          // -------------------------------------------------------------------
          // PHASE 2: Ticket Feeding (0.08 – 0.78) ~2170ms
          // -------------------------------------------------------------------
          final feedT = ((progress - 0.08) / 0.70).clamp(0.0, 1.0);
          final feedProgress = Curves.easeInOutSine.transform(feedT);

          // Micro-vibration on printer housing during feed only (max 0.6px)
          final isPrinting = progress >= 0.08 && progress <= 0.78;
          final printerVibration = isPrinting
              ? (math.sin(progress * 60.0) * 0.6)
              : 0.0;

          // -------------------------------------------------------------------
          // PHASE 3: Settle motion (0.78 – 0.90) ~370ms
          // -------------------------------------------------------------------
          double settleOffset = 0.0;
          if (progress > 0.78 && progress <= 0.90) {
            final settleT = (progress - 0.78) / 0.12;
            settleOffset = math.sin(settleT * math.pi) * 2.0;
          }

          // -------------------------------------------------------------------
          // PHASE 4: Actions Fade/Slide (0.90 – 1.00) ~310ms
          // -------------------------------------------------------------------
          final actionsT = ((progress - 0.90) / 0.10).clamp(0.0, 1.0);
          final actionsOpacity =
              actionsT >= 1.0 ? 1.0 : Curves.easeOut.transform(actionsT);
          final actionsSlideY = (1.0 - actionsOpacity) * 14.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Success Icon & Confirmation Title
              Center(
                child: Transform.scale(
                  scale: effectiveScale,
                  child: Opacity(
                    opacity: checkOpacity,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF86EFAC),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(
                              alpha: (0.28 * checkOpacity).clamp(0.0, 0.28),
                            ),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Color(0xFF16A34A),
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.bookingSuccessTitle,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: const Color(0xFF101828),
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.bookingSuccessSubtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 2. Printer & Portrait Ticket Printing Stage
              Center(
                child: SizedBox(
                  width: ticketWidth + 24.0,
                  height: 56.0 + ticketHeight + 10.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // LAYER 1: The Emergent Portrait Ticket (physically clipped behind printer)
                      Positioned(
                        top: 48.0, // Aligned with the printer output slot
                        left: 12.0,
                        width: ticketWidth,
                        height: ticketHeight + 10.0,
                        child: ClipRect(
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              -(ticketHeight * (1.0 - feedProgress)) +
                                  settleOffset,
                            ),
                            child: BookingQrTicketCard(
                              booking: widget.booking,
                              ticketWidth: ticketWidth,
                              ticketHeight: ticketHeight,
                              isAr: isAr,
                              locale: locale,
                              feedProgress: feedProgress,
                            ),
                          ),
                        ),
                      ),

                      // LAYER 2: Printer Housing Layer (rendered ON TOP of ticket)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 56.0,
                        child: Transform.translate(
                          offset: Offset(printerVibration, 0),
                          child: _TicketPrinterHousing(
                            width: ticketWidth + 24.0,
                            ticketWidth: ticketWidth,
                            slotGlow: slotGlow,
                            isPrinting: isPrinting,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Post-Print Action Buttons (Side-by-Side: View My Trips + Back to Home)
              Opacity(
                opacity: actionsOpacity,
                child: Transform.translate(
                  offset: Offset(0, actionsSlideY),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      children: [
                        // Primary Action: View My Trips (Filled AMOMY Blue)
                        Expanded(
                          child: AppButton(
                            label: l10n.viewMyTrips,
                            icon: const Icon(
                              AppIcons.bus,
                              size: 18,
                              color: Colors.white,
                            ),
                            height: 48.0,
                            isFullWidth: true,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            onPressed: actionsOpacity > 0.5
                                ? () => context.go('/trips')
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Secondary Action: Back to Home (Soft / Outlined)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: actionsOpacity > 0.5
                                ? () => context.go('/home')
                                : null,
                            icon: const Icon(
                              AppIcons.home,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              isAr ? 'العودة للرئيسية' : 'Back to Home',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              side: const BorderSide(
                                color: Color(0xFFCBD5E1),
                                width: 1.4,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.radiusLg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact stylized digital boarding-ticket machine housing.
class _TicketPrinterHousing extends StatelessWidget {
  final double width;
  final double ticketWidth;
  final double slotGlow;
  final bool isPrinting;

  const _TicketPrinterHousing({
    required this.width,
    required this.ticketWidth,
    required this.slotGlow,
    required this.isPrinting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 56.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(10),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF0B192C), // Sleek AMOMY Dark Navy
          ],
        ),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
            left: 16,
            right: 16,
            height: 1.0,
            child: Container(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            ),
          ),

          // Center Branding & Status LED
          Positioned(
            top: 10,
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
                        color: const Color(0xFF22C55E).withValues(
                          alpha: isPrinting ? 0.9 : 0.5,
                        ),
                        blurRadius: isPrinting ? 6 : 3,
                        spreadRadius: isPrinting ? 1 : 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AMOMY DIGITAL DISPENSER',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Output Slot Cavity at bottom matching portrait ticket width
          Positioned(
            bottom: 3,
            child: Container(
              width: ticketWidth + 8.0,
              height: 7.5,
              decoration: BoxDecoration(
                color: const Color(0xFF020617), // Deep black cavity
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(
                      alpha: (slotGlow * 0.4).clamp(0.0, 0.4),
                    ),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 1),
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
