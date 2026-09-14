import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class AmountStepWidget extends StatefulWidget {
  final int initialAmount;
  final int availableBalance;
  final int minimumPoints;
  final double egpPerPoint;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onNext;

  const AmountStepWidget({
    super.key,
    required this.initialAmount,
    required this.availableBalance,
    this.minimumPoints = 200,
    this.egpPerPoint = 1.0,
    required this.onAmountChanged,
    required this.onNext,
  });

  @override
  State<AmountStepWidget> createState() => _AmountStepWidgetState();
}

class _AmountStepWidgetState extends State<AmountStepWidget> {
  late final TextEditingController _customController;
  final List<int> _presetAmounts = const [200, 250, 300, 500, 1000];
  int? _selectedPreset;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAmount >= widget.minimumPoints ? widget.initialAmount : widget.minimumPoints;
    _customController = TextEditingController(text: init > 0 ? init.toString() : '');
    if (_presetAmounts.contains(init)) {
      _selectedPreset = init;
    } else {
      _selectedPreset = null;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int get _currentAmount {
    return int.tryParse(_customController.text) ?? 0;
  }

  void _selectPreset(int preset) {
    setState(() {
      _selectedPreset = preset;
      _customController.text = preset.toString();
      _customController.selection = TextSelection.fromPosition(
        TextPosition(offset: _customController.text.length),
      );
    });
    widget.onAmountChanged(preset);
  }

  void _onCustomChanged(String text) {
    final parsed = int.tryParse(text) ?? 0;
    setState(() {
      if (_presetAmounts.contains(parsed)) {
        _selectedPreset = parsed;
      } else {
        _selectedPreset = null;
      }
    });
    widget.onAmountChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = NumberFormat('#,###');
    final amount = _currentAmount;
    final isBelowMin = amount > 0 && amount < widget.minimumPoints;
    final isValid = amount >= widget.minimumPoints;
    final expectedEgp = (amount * widget.egpPerPoint).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Available balance header card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.wallet,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapW10,
                  Text(
                    l10n.availableBalanceLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${formatter.format(widget.availableBalance)} ${l10n.ptsUnit}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapH20,

        // 2. Section Title
        Text(
          l10n.howManyPointsToAdd,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        AppSpacing.gapH12,

        // 3. Custom Amount Input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.customAmount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapH6,
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isBelowMin
                      ? AppColors.error
                      : (_customController.text.isNotEmpty)
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  AppSpacing.gapW14,
                  const Icon(
                    AppIcons.edit,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.gapW10,
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: _onCustomChanged,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: '200+',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.ptsUnit,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Inline validation if < 200
        if (isBelowMin) ...[
          AppSpacing.gapH6,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                AppSpacing.gapW6,
                Text(
                  l10n.minTopupNotice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
        AppSpacing.gapH14,

        // 4. Preset chips (Quick selection under the custom input)
        Row(
          children: _presetAmounts.map((preset) {
            final isSelected = _selectedPreset == preset;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => _selectPreset(preset),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FC) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$preset',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.ptsUnit,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        AppSpacing.gapH16,

        // 5. Expected conversion card
        if (amount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_pound_rounded, size: 18, color: Color(0xFF16A34A)),
                    AppSpacing.gapW8,
                    Text(
                      l10n.transferAmount,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                Text(
                  'EGP ${formatter.format(expectedEgp)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),

        const Spacer(),

        // 6. Continue Button
        AppButton(
          label: l10n.continueAction,
          onPressed: isValid ? widget.onNext : null,
          isFullWidth: true,
        ),
      ],
    );
  }
}
