import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/assets/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../topup/domain/entities/topup_entities.dart';

class WalletPendingPointsSection extends StatefulWidget {
  final List<TopUpRequest> requests;
  final void Function(TopUpRequest request)? onResubmit;

  const WalletPendingPointsSection({
    super.key,
    required this.requests,
    this.onResubmit,
  });

  @override
  State<WalletPendingPointsSection> createState() => _WalletPendingPointsSectionState();
}

class _WalletPendingPointsSectionState extends State<WalletPendingPointsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final formatter = NumberFormat('#,###');
    final dateFormat = DateFormat('d MMM • HH:mm', isAr ? 'ar' : 'en');

    final activeOrRejected = widget.requests.where((r) {
      return r.status == TopUpStatus.pending ||
          r.status == TopUpStatus.rejected ||
          r.status == TopUpStatus.awaitingPayment;
    }).toList();

    if (activeOrRejected.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleRequests = _showAll ? activeOrRejected : activeOrRejected.take(2).toList();
    final hasMore = activeOrRejected.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.pendingPoints,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
                letterSpacing: -0.2,
              ),
            ),
            if (hasMore)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _showAll ? l10n.backAction : l10n.viewAllPendingTopUps,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // List of pending / rejected cards
        ...visibleRequests.map((req) {
          final isPending = req.status == TopUpStatus.pending;
          final isRejected = req.status == TopUpStatus.rejected;

          final Color cardBg;
          final Color cardBorder;
          final String statusText;
          final Color statusBg;
          final Color statusColor;

          if (isRejected) {
            cardBg = Colors.white;
            cardBorder = const Color(0xFFFDA29B);
            statusText = l10n.statusRejected;
            statusBg = const Color(0xFFFEE4E2);
            statusColor = const Color(0xFFD92D20);
          } else if (isPending) {
            cardBg = Colors.white;
            cardBorder = const Color(0xFFFEDF89);
            statusText = l10n.statusPendingReview;
            statusBg = const Color(0xFFFEF0C7);
            statusColor = const Color(0xFFB54708);
          } else {
            cardBg = Colors.white;
            cardBorder = const Color(0xFFE4EBF2);
            statusText = l10n.statusAwaitingPayment;
            statusBg = const Color(0xFFF2F4F7);
            statusColor = const Color(0xFF475467);
          }

          final isInsta = req.paymentMethodCode.toUpperCase().contains('INSTAPAY');
          final logoAsset = isInsta ? AppAssets.instapayLogo : AppAssets.vodafoneCashLogo;
          final methodName = req.paymentMethodNameAr != null && req.paymentMethodNameAr!.isNotEmpty
              ? (isAr ? req.paymentMethodNameAr! : (req.paymentMethodNameEn ?? req.paymentMethodCode))
              : (isInsta ? (isAr ? 'إنستاباي' : 'InstaPay') : (isAr ? 'فودافون كاش' : 'Vodafone Cash'));

          final dateStr = dateFormat.format((req.submittedAt ?? req.createdAt).toLocal());

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF101828).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading payment method logo (adaptive width, 38 height)
                Container(
                  width: isInsta ? 52 : 46,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRejected
                          ? const Color(0xFFFDA29B)
                          : (isPending ? const Color(0xFFFEDF89) : const Color(0xFFE4EBF2)),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      logoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Center: Visually dominant points amount, Method name + EGP and timestamp/reason
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // VISUALLY DOMINANT POINTS AMOUNT
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${formatter.format(req.requestedAmount)} ${l10n.ptsUnit}',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF101828),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Payment method name + EGP amount
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            methodName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'EGP ${formatter.format(req.expectedAmountEgp.round())}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      if (isRejected) ...[
                        Text(
                          req.rejectionReason != null && req.rejectionReason!.trim().isNotEmpty
                              ? req.rejectionReason!
                              : l10n.paymentCouldNotBeVerified,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD92D20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          '${l10n.submittedOn} $dateStr',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Trailing: Status pill & Resubmit CTA if rejected
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (isRejected) ...[
                      const SizedBox(height: 8),
                      Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => widget.onResubmit?.call(req),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.refresh_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                AppSpacing.gapW4,
                                Text(
                                  l10n.resubmit,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
