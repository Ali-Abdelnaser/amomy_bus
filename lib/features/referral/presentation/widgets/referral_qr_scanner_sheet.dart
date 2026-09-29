import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Modal bottom sheet for scanning a referral QR code.
///
/// Scans QR code containing `amomy://invite?code=CODE` or plain `CODE`.
/// Returns the extracted code upon detection.
class ReferralQrScannerSheet extends StatefulWidget {
  const ReferralQrScannerSheet({super.key});

  /// Opens the scanner sheet and returns the detected referral code if any.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.black,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const ReferralQrScannerSheet(),
    );
  }

  /// Extracts the referral code from scanned string.
  /// Handles `amomy://invite?code=CODE`, deep links, or plain codes.
  static String? extractReferralCode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final uri = Uri.parse(trimmed);
      if (uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']?.trim();
        if (code != null && code.isNotEmpty) {
          return code.toUpperCase();
        }
      }
    } catch (_) {}

    final match = RegExp(
      r'[?&]code=([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      final code = match.group(1)?.trim();
      if (code != null && code.isNotEmpty) {
        return code.toUpperCase();
      }
    }

    // Direct plain code format fallback (alphanumeric 3-30 chars)
    if (RegExp(r'^[A-Za-z0-9_-]{3,30}$').hasMatch(trimmed)) {
      return trimmed.toUpperCase();
    }

    return null;
  }

  @override
  State<ReferralQrScannerSheet> createState() => _ReferralQrScannerSheetState();
}

class _ReferralQrScannerSheetState extends State<ReferralQrScannerSheet> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      final extracted = ReferralQrScannerSheet.extractReferralCode(raw);
      if (extracted != null && extracted.isNotEmpty) {
        _hasScanned = true;
        Navigator.of(context).pop(extracted);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Camera Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.camera,
                          size: 48,
                          color: Colors.white54,
                        ),
                        AppSpacing.gapH16,
                        Text(
                          isAr
                              ? 'تعذر الوصول إلى الكاميرا'
                              : 'Camera access unavailable',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapH8,
                        Text(
                          isAr
                              ? 'يرجى التأكد من منح إذن استخدام الكاميرا من إعدادات الجهاز.'
                              : 'Please ensure camera permissions are granted in settings.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Viewfinder reticle overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Animated or static corner accents
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 24,
                      height: 4,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 24,
                      height: 4,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      width: 24,
                      height: 4,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 24,
                      height: 4,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header Controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(AppIcons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                ),
                Text(
                  isAr ? 'مسح رمز QR للدعوة' : 'Scan Referral QR',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                  icon: Icon(
                    _isTorchOn ? AppIcons.flash : AppIcons.flashOff,
                    color: _isTorchOn ? Colors.amber : Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          // Instruction footer
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isAr
                    ? 'وجّه الكاميرا نحو رمز QR الخاص بصديقك لقراءة كود الدعوة'
                    : 'Point camera at your friend\'s QR to read referral code',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
