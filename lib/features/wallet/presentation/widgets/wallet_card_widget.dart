import 'package:flutter/material.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class WalletCardWidget extends StatelessWidget {
  const WalletCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 1300 x 708 is the exact card boundary inside the 1566 x 1005 asset canvas
    return AspectRatio(
      aspectRatio: 1300 / 708,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Scale factor to map the active 1300x708 card region to fill [w, h]
          final imgWidth = w * (1566 / 1300);
          final imgHeight = h * (1005 / 708);
          final imgLeft = -w * (135 / 1300);
          final imgTop = -h * (156 / 708);

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepNavy.withValues(alpha: 0.32),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Authoritative White/Blue AMOMY Card Asset cropped to exact card bounds
                  Positioned(
                    left: imgLeft,
                    top: imgTop,
                    width: imgWidth,
                    height: imgHeight,
                    child: Image.asset(
                      AppAssets.cardWhiteBlue,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  // 2. Subtle reflective light / depth overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.14),
                            Colors.white.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.12),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Gentle inner border highlight
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // 4. ONLY NFC Contactless Icon on Card (Clean, uncrowded, prominent)
                  PositionedDirectional(
                    top: 18,
                    end: 20,
                    child: Icon(
                      Icons.contactless_rounded,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
