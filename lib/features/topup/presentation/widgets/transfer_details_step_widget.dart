import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class TransferDetailsStepWidget extends StatefulWidget {
  final String initialReference;
  final List<int>? proofBytes;
  final String? proofFileName;
  final ValueChanged<String> onReferenceChanged;
  final void Function({
    required List<int> bytes,
    required String extension,
    required String fileName,
  }) onProofSelected;
  final VoidCallback onClearProof;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const TransferDetailsStepWidget({
    super.key,
    required this.initialReference,
    required this.proofBytes,
    required this.proofFileName,
    required this.onReferenceChanged,
    required this.onProofSelected,
    required this.onClearProof,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<TransferDetailsStepWidget> createState() => _TransferDetailsStepWidgetState();
}

class _TransferDetailsStepWidgetState extends State<TransferDetailsStepWidget> {
  late final TextEditingController _refController;
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(text: widget.initialReference);
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final name = file.name;
        final ext = name.contains('.') ? name.split('.').last : 'jpg';

        widget.onProofSelected(
          bytes: bytes,
          extension: ext,
          fileName: name,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.topUpErrorUploadFailed),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasRef = _refController.text.trim().isNotEmpty;
    final hasProof = widget.proofBytes != null && widget.proofBytes!.isNotEmpty;
    final canProceed = hasRef && hasProof;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section: Payment Reference
          Text(
            l10n.topUpTransactionReference,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapH4,
          Text(
            l10n.topUpTransactionReferenceHelper,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapH12,
          TextField(
            controller: _refController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: l10n.topUpTransactionReferenceHint,
              prefixIcon: const Icon(AppIcons.info, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (val) {
              widget.onReferenceChanged(val);
              setState(() {});
            },
          ),
          AppSpacing.gapH24,

          // Section: Proof Screenshot
          Text(
            l10n.topUpPaymentProof,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapH8,

          if (!hasProof) ...[
            // Empty / Upload box
            InkWell(
              onTap: _isPicking ? null : _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.add,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    AppSpacing.gapH12,
                    Text(
                      l10n.topUpUploadScreenshot,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Text(
                      'JPG, PNG (Max 10MB)',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Preview card
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      Uint8List.fromList(widget.proofBytes!),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.proofFileName ?? 'screenshot.jpg',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.gapH4,
                        Row(
                          children: [
                            const Icon(AppIcons.check, size: 14, color: AppColors.success),
                            AppSpacing.gapW4,
                            Text(
                              l10n.bookingStatusConfirmed,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.refresh, color: AppColors.primary),
                    tooltip: l10n.topUpChangeScreenshot,
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, color: AppColors.error),
                    tooltip: l10n.dismiss,
                    onPressed: widget.onClearProof,
                  ),
                ],
              ),
            ),
          ],

          AppSpacing.gapH32,

          // Bottom Buttons
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
                  label: l10n.continueAction,
                  onPressed: canProceed ? widget.onNext : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
