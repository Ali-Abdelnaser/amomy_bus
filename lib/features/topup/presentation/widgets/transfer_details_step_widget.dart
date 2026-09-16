import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_date_picker_modal.dart';

class TransferDetailsStepWidget extends StatefulWidget {
  final int points;
  final double amountEgp;
  final String? publicId;
  final String initialSenderPhone;
  final String initialReference;
  final DateTime? initialTransferredAt;
  final List<int>? proofBytes;
  final String? proofFileName;
  final bool isSubmitting;
  final bool isResubmit;
  final String? rejectionReason;
  final ValueChanged<String> onSenderPhoneChanged;
  final ValueChanged<String> onReferenceChanged;
  final ValueChanged<DateTime> onTransferredAtChanged;
  final void Function({
    required List<int> bytes,
    required String extension,
    required String fileName,
  })
  onProofSelected;
  final VoidCallback onClearProof;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const TransferDetailsStepWidget({
    super.key,
    required this.points,
    required this.amountEgp,
    this.publicId,
    required this.initialSenderPhone,
    required this.initialReference,
    this.initialTransferredAt,
    required this.proofBytes,
    required this.proofFileName,
    required this.isSubmitting,
    this.isResubmit = false,
    this.rejectionReason,
    required this.onSenderPhoneChanged,
    required this.onReferenceChanged,
    required this.onTransferredAtChanged,
    required this.onProofSelected,
    required this.onClearProof,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<TransferDetailsStepWidget> createState() =>
      _TransferDetailsStepWidgetState();
}

class _TransferDetailsStepWidgetState extends State<TransferDetailsStepWidget> {
  late final TextEditingController _phoneController;
  late final TextEditingController _refController;
  late DateTime _selectedDateTime;
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialSenderPhone);
    _refController = TextEditingController(text: widget.initialReference);
    _selectedDateTime = widget.initialTransferredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _refController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    final clean = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = (clean.length == 12 && clean.startsWith('201'))
        ? '01${clean.substring(3)}'
        : clean;
    return RegExp(r'^01[0125][0-9]{8}$').hasMatch(normalized);
  }

  bool get _hasProof =>
      widget.proofBytes != null && widget.proofBytes!.isNotEmpty;

  bool get _canSubmit => _isPhoneValid && _hasProof && !widget.isSubmitting;

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final name = file.name;
        final ext = name.contains('.') ? name.split('.').last : 'jpg';

        widget.onProofSelected(bytes: bytes, extension: ext, fileName: name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorOccurred),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showAppDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null && mounted) {
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() => _selectedDateTime = combined);
        widget.onTransferredAtChanged(combined);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = NumberFormat('#,###');
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final dtFormat = DateFormat('d MMM yyyy • hh:mm a', isAr ? 'ar' : 'en');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Frozen request summary chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatter.format(widget.points)} ${l10n.ptsUnit}  •  EGP ${formatter.format(widget.amountEgp.round())}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.publicId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.requestIdLabel}: ${widget.publicId}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.mobileCash,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isResubmit &&
              widget.rejectionReason != null &&
              widget.rejectionReason!.trim().isNotEmpty) ...[
            AppSpacing.gapH12,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE4E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDA29B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: Color(0xFFD92D20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.paymentCouldNotBeVerified,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD92D20),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.rejectionReason!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB42318),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.gapH20,

          // 2. Sender Phone Number (01XXXXXXXXX)
          Text(
            l10n.senderPhoneLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH6,
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: l10n.senderPhoneHint,
              prefixIcon: const Icon(
                Icons.phone_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (val) {
              widget.onSenderPhoneChanged(val);
              setState(() {});
            },
          ),
          if (_phoneController.text.isNotEmpty && !_isPhoneValid) ...[
            AppSpacing.gapH4,
            Text(
              l10n.senderPhoneInvalid,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
          AppSpacing.gapH16,

          // 3. Transfer Reference / Transaction ID
          Text(
            l10n.transferReferenceLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH6,
          TextField(
            controller: _refController,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: l10n.transferReferenceOptional,
              prefixIcon: const Icon(
                Icons.tag_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (val) {
              widget.onReferenceChanged(val);
              setState(() {});
            },
          ),
          AppSpacing.gapH16,

          // 4. Transfer Date & Time
          Text(
            l10n.transferDateTimeLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH6,
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapW10,
                  Expanded(
                    child: Text(
                      dtFormat.format(_selectedDateTime),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapH16,

          // 5. Payment Screenshot (Required)
          Text(
            l10n.paymentScreenshotLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH8,

          if (!_hasProof) ...[
            InkWell(
              onTap: _isPicking ? null : () => _pickImage(ImageSource.gallery),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    AppSpacing.gapH10,
                    Text(
                      l10n.tapToUploadScreenshot,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'JPG, PNG, WebP (Max 10MB)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      Uint8List.fromList(widget.proofBytes!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.proofFileName ?? 'receipt.jpg',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF16A34A),
                            ),
                            AppSpacing.gapW4,
                            Text(
                              l10n.screenshotAttached,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: widget.onClearProof,
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.gapH24,

          // 6. Action buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: AppButton(
                  label: l10n.backAction,
                  variant: AppButtonVariant.outline,
                  onPressed: widget.onBack,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                flex: 2,
                child: AppButton(
                  label: widget.isResubmit
                      ? l10n.resubmitForReview
                      : l10n.submitDetailsAction,
                  isLoading: widget.isSubmitting,
                  onPressed: _canSubmit ? widget.onSubmit : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
