import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Standards-compliant machine-readable QR code ticket widget.
/// Encodes strictly the [data] (booking.qrToken) with ISO/IEC 18004 compliance.
class AppQrTicketWidget extends StatelessWidget {
  final String data;
  final double size;

  const AppQrTicketWidget({
    super.key,
    required this.data,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: data.trim().isEmpty
          ? const Center(
              child: Icon(
                Icons.qr_code_2,
                size: 48,
                color: Color(0xFF98A2B3),
              ),
            )
          : QrImageView(
              data: data,
              version: QrVersions.auto,
              size: size - 16,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF101828),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF101828),
              ),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
    );
  }
}

