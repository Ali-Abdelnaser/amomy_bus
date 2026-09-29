import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../domain/entities/referral_entities.dart';
import '../cubit/referral_cubit.dart';
import '../cubit/referral_state.dart';
import 'referral_qr_scanner_sheet.dart';

class WhoInvitedMeTab extends StatefulWidget {
  final ReferralDashboard dashboard;
  final String? initialCode;

  const WhoInvitedMeTab({
    super.key,
    required this.dashboard,
    this.initialCode,
  });

  @override
  State<WhoInvitedMeTab> createState() => _WhoInvitedMeTabState();
}

class _WhoInvitedMeTabState extends State<WhoInvitedMeTab> {
  late final TextEditingController _codeController;
  bool _autoPreviewed = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerInitialPreview();
      });
    }
  }

  @override
  void didUpdateWidget(covariant WhoInvitedMeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCode != null &&
        widget.initialCode != oldWidget.initialCode &&
        widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
      _autoPreviewed = false;
      _triggerInitialPreview();
    }
  }

  void _triggerInitialPreview() {
    if (_autoPreviewed || widget.dashboard.isLinked) return;
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      _autoPreviewed = true;
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      context.read<ReferralCubit>().previewCode(code, isArabic: isAr);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onPreviewPressed() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final code = _codeController.text.trim();
    context.read<ReferralCubit>().previewCode(code, isArabic: isAr);
  }

  void _onConfirmBind(String code) {
    final source = widget.initialCode != null && widget.initialCode!.isNotEmpty
        ? 'deep_link'
        : 'manual_code';

    context.read<ReferralCubit>().bindCode(
          code: code,
          source: source,
        );
  }

  Future<void> _onScanQr() async {
    final scannedCode = await ReferralQrScannerSheet.show(context);
    if (scannedCode == null || scannedCode.isEmpty || !mounted) return;

    _codeController.text = scannedCode;
    setState(() {});

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    context.read<ReferralCubit>().previewCode(scannedCode, isArabic: isAr);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (widget.dashboard.isLinked) {
      return _buildAlreadyLinkedView(context, isAr);
    }

    return _buildNotLinkedView(context, isAr);
  }

  /// 1. VIEW WHEN ALREADY LINKED
  Widget _buildAlreadyLinkedView(BuildContext context, bool isAr) {
    final invitedBy = widget.dashboard.invitedBy!;
    final progress = widget.dashboard.inviteeProgress;
    final milestoneTotal = progress?.milestoneTripCount ?? 3;
    final tripCount = progress?.qualifiedTripCount ?? 0;
    final tripProgress = tripCount.clamp(0, milestoneTotal);
    final firstTripRewardGranted = progress?.firstTripRewardGranted ?? false;
    final firstTripRewardPoints = progress?.firstTripRewardPoints.toInt() ?? 5;
    final dateStr = DateFormat.yMMMd(isAr ? 'ar' : 'en').format(invitedBy.acceptedAt);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Linked Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA6F4C5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF12B76A),
                ),
                child: const Icon(
                  AppIcons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'حسابك مربوط بدعوة بنجاح'
                          : 'Your account is linked to an invite',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF027A48),
                      ),
                    ),
                    Text(
                      isAr
                          ? 'تم ربط الحساب بتاريخ $dateStr ولا يمكن تغييره.'
                          : 'Linked on $dateStr and cannot be changed.',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF05603A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapH20,

        // Inviter Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'تمت دعوتك بواسطة' : 'INVITED BY',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              AppSpacing.gapH12,
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: invitedBy.inviterAvatarUrl != null
                        ? NetworkImage(invitedBy.inviterAvatarUrl!)
                        : null,
                    child: invitedBy.inviterAvatarUrl == null
                        ? Text(
                            invitedBy.inviterName.isNotEmpty
                                ? invitedBy.inviterName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  AppSpacing.gapW14,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitedBy.inviterName,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isAr ? 'عضو في مجتمع عمومي باص' : 'AMOMY Bus Member',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.gapH16,

        // Trip Progress Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'تقدم رحلاتك المؤهلة' : 'Your Trip Progress',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tripProgress >= milestoneTotal
                          ? const Color(0xFFECFDF3)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAr
                          ? '$tripProgress من $milestoneTotal رحلات'
                          : '$tripProgress / $milestoneTotal trips',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tripProgress >= milestoneTotal
                            ? const Color(0xFF027A48)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH12,
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: tripProgress / milestoneTotal,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF2F4F7),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tripProgress >= milestoneTotal
                        ? const Color(0xFF12B76A)
                        : AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.gapH14,

              // 5-Point First Trip Reward Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: firstTripRewardGranted
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: firstTripRewardGranted
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      firstTripRewardGranted
                          ? AppIcons.checkCircle
                          : AppIcons.gift,
                      size: 20,
                      color: firstTripRewardGranted
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                    ),
                    AppSpacing.gapW10,
                    Expanded(
                      child: Text(
                        firstTripRewardGranted
                          ? (isAr
                              ? 'تم استلام $firstTripRewardPoints نقاط مكافأة أول رحلة في محفظتك بنجاح ✓'
                              : '$firstTripRewardPoints points 1st trip reward granted to your wallet ✓')
                          : (isAr
                              ? 'أكمل رحلتك الأولى وستحصل على $firstTripRewardPoints نقاط مكافأة هدية في محفظتك!'
                              : 'Complete your 1st trip to earn $firstTripRewardPoints bonus reward points!'),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: firstTripRewardGranted
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. VIEW WHEN NOT LINKED
  Widget _buildNotLinkedView(BuildContext context, bool isAr) {
    return BlocConsumer<ReferralCubit, ReferralState>(
      listener: (context, state) {
        if (state.bindStatus == ReferralBindStatus.success) {
          AppSnackBar.showSuccess(
            context,
            isAr
                ? 'تم ربط كود الدعوة بنجاح!'
                : 'Referral code linked successfully!',
          );
        } else if (state.bindStatus == ReferralBindStatus.error &&
            state.bindError != null) {
          AppSnackBar.showError(context, state.bindError!);
        }
      },
      builder: (context, state) {
        final isEnabled = widget.dashboard.program.enabled;
        final preview = state.preview;
        final isPreviewValid = state.previewStatus == ReferralPreviewStatus.success &&
            preview != null &&
            preview.valid;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Explanatory Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          AppIcons.ticket,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      AppSpacing.gapW10,
                      Text(
                        isAr ? 'هل دعاك صديق؟' : 'Invited by a friend?',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH8,
                  Text(
                    isAr
                        ? 'أدخل كود الدعوة لمعاينته وتأكيده والحصول على نقاط مجانية عند إتمام أول رحلة لك.'
                        : 'Enter the referral code to preview and confirm it, earning bonus points upon your first trip.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  AppSpacing.gapH16,

                  // CODE INPUT FIELD
                  TextField(
                    controller: _codeController,
                    enabled: isEnabled && !state.isBindLoading,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'AMY-••••••••',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.0,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(
                        AppIcons.ticket,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: _codeController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(AppIcons.close, size: 18),
                              onPressed: () {
                                _codeController.clear();
                                context.read<ReferralCubit>().clearPreview();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      context.read<ReferralCubit>().clearPreview();
                      setState(() {});
                    },
                  ),
                  AppSpacing.gapH12,

                  // PREVIEW BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isEnabled &&
                              _codeController.text.trim().isNotEmpty &&
                              !state.isPreviewLoading &&
                              !state.isBindLoading
                          ? _onPreviewPressed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: state.isPreviewLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isAr ? 'معاينة كود الدعوة' : 'Preview Referral Code',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  AppSpacing.gapH10,

                  // SCAN QR BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isEnabled && !state.isPreviewLoading && !state.isBindLoading
                          ? _onScanQr
                          : null,
                      icon: const Icon(AppIcons.qrCode, size: 18),
                      label: Text(
                        isAr ? 'مسح QR صديقك' : 'Scan Friend\'s QR',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH16,

            // PREVIEW ERROR BANNER
            if (state.previewStatus == ReferralPreviewStatus.error &&
                state.previewError != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: const Color(0xFFFECDCA)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.warningCircle,
                      color: AppColors.error,
                      size: 20,
                    ),
                    AppSpacing.gapW10,
                    Expanded(
                      child: Text(
                        state.previewError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH16,
            ],

            // PREVIEW SUCCESS CARD + CONFIRM BUTTON (Never auto-bind!)
            if (isPreviewValid) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: preview.inviterAvatarUrl != null
                              ? NetworkImage(preview.inviterAvatarUrl!)
                              : null,
                          child: preview.inviterAvatarUrl == null
                              ? Text(
                                  preview.inviterName != null &&
                                          preview.inviterName!.isNotEmpty
                                      ? preview.inviterName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'صاحب الدعوة' : 'INVITER',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                preview.inviterName ?? '—',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAr ? 'كود صالح ✓' : 'Valid Code ✓',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF027A48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH14,
                    const Divider(height: 1, color: AppColors.border),
                    AppSpacing.gapH14,

                    // Reward details
                    Row(
                      children: [
                        const Icon(
                          AppIcons.gift,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          child: Text(
                            isAr
                                ? 'ستحصل على ${preview.inviteeFirstRewardPoints?.toInt() ?? 5} نقاط هدية في محفظتك فور إتمام رحلتك الأولى!'
                                : 'You will receive ${preview.inviteeFirstRewardPoints?.toInt() ?? 5} bonus points upon completing your first trip!',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH18,

                    // CONFIRM BIND ACTION (User must click to confirm!)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state.isBindLoading
                            ? null
                            : () => _onConfirmBind(_codeController.text),
                        icon: state.isBindLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(AppIcons.checkCircle, size: 18),
                        label: Text(
                          isAr
                              ? 'تأكيد واستخدام الكود'
                              : 'Confirm & Apply Code',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF027A48),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
