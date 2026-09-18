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
  late final FocusNode _focusNode;
  bool _isFocused = false;
  final List<int> _presetAmounts = const [200, 250, 300, 500, 1000];
  int? _selectedPreset;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAmount >= widget.minimumPoints
        ? widget.initialAmount
        : widget.minimumPoints;
    _customController = TextEditingController(
      text: init > 0 ? init.toString() : '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    if (_presetAmounts.contains(init)) {
      _selectedPreset = init;
    } else {
      _selectedPreset = null;
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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

    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
            AppSpacing.gapH8,
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              behavior: HitTestBehavior.translucent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isBelowMin
                        ? AppColors.error
                        : _isFocused
                        ? AppColors.primary
                        : (_customController.text.isNotEmpty)
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : const Color(0xFFE2E8F0),
                    width: _isFocused || isBelowMin ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    if (_isFocused)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      )
                    else if (isBelowMin)
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isBelowMin
                            ? AppColors.errorLight
                            : _isFocused
                            ? AppColors.primaryLight
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppIcons.wallet,
                        size: 20,
                        color: isBelowMin
                            ? AppColors.error
                            : _isFocused
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: isRtl ? TextAlign.right : TextAlign.left,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: _onCustomChanged,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: '${widget.minimumPoints}+',
                          hintStyle: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    if (_customController.text.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () {
                          _customController.clear();
                          _onCustomChanged('');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.close,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      AppSpacing.gapW8,
                    ],
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _isFocused
                            ? AppColors.primary
                            : const Color(0xFFEFF6FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.ptsUnit,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _isFocused ? Colors.white : AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
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
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
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
                      color: isSelected
                          ? const Color(0xFFEFF6FC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
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
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.ptsUnit,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
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
                    const Icon(
                      Icons.currency_pound_rounded,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
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
