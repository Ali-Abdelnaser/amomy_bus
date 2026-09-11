import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class AmountStepWidget extends StatefulWidget {
  final int initialAmount;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onNext;

  const AmountStepWidget({
    super.key,
    required this.initialAmount,
    required this.onAmountChanged,
    required this.onNext,
  });

  @override
  State<AmountStepWidget> createState() => _AmountStepWidgetState();
}

class _AmountStepWidgetState extends State<AmountStepWidget> {
  late final TextEditingController _controller;
  final List<int> _quickAmounts = const [100, 200, 500, 1000];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0 ? widget.initialAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQuickSelected(int val) {
    _controller.text = val.toString();
    widget.onAmountChanged(val);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentVal = int.tryParse(_controller.text) ?? 0;
    final isValid = currentVal > 0;
    final formatter = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Ratio Notice
        Text(
          l10n.topUpAmountTitle,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.gapH4,
        Text(
          l10n.topUpAmountHint,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.gapH16,

        // Ratio Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.info, size: 18, color: AppColors.primary),
              AppSpacing.gapW8,
              Expanded(
                child: Text(
                  l10n.topUpPointsRatio,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapH20,

        // Amount Input Field
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  labelText: l10n.topUpAmountTitle,
                  hintText: '0',
                  suffixText: 'EGP',
                  suffixStyle: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: const Icon(AppIcons.wallet, color: AppColors.primary),
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
                  final parsed = int.tryParse(val) ?? 0;
                  widget.onAmountChanged(parsed);
                  setState(() {});
                },
              ),
              if (currentVal > 0) ...[
                AppSpacing.gapH12,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.topUpExpectedPoints,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${formatter.format(currentVal)} ${l10n.pointsUnit}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        AppSpacing.gapH16,

        // Quick amount chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((val) {
            final isSelected = currentVal == val;
            return ChoiceChip(
              label: Text(
                '$val EGP',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onSelected: (_) => _onQuickSelected(val),
            );
          }).toList(),
        ),

        const Spacer(),

        // Next Button
        AppButton(
          label: l10n.continueAction,
          onPressed: isValid ? widget.onNext : null,
          isFullWidth: true,
        ),
      ],
    );
  }
}
