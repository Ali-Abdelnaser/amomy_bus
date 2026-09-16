import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Reusable form text field with brand styling, prefix/suffix icons, validation, and clear error handling.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final dynamic prefixIcon;
  final dynamic suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.focusNode,
  });

  Widget? _buildIcon(dynamic icon) {
    if (icon == null) return null;
    if (icon is Widget) return icon;
    if (icon is IconData) {
      return Icon(icon, color: const Color(0xFF64748B), size: 20);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          focusNode: focusNode,
          style: AppTextStyles.bodyMedium.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.disabled,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: _buildIcon(prefixIcon),
            suffixIcon: _buildIcon(suffixIcon),
          ),
        ),
      ],
    );
  }
}

/// Specialized password field with toggleable eye visibility icon
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.done,
    this.autofillHints,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      obscureText: _obscure,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      keyboardType: TextInputType.visiblePassword,
      prefixIcon: const Icon(AppIcons.lock, color: Color(0xFF64748B), size: 20),
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? AppIcons.eye : AppIcons.eyeOff,
          color: const Color(0xFF64748B),
          size: 20,
        ),
        splashRadius: 20,
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

/// Search input field with search icon and optional clear button
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint ?? 'Search...',
      onChanged: onChanged,
      prefixIcon: const Icon(
        AppIcons.search,
        color: AppColors.textSecondary,
        size: 20,
      ),
      suffixIcon: controller != null && controller!.text.isNotEmpty
          ? IconButton(
              icon: const Icon(
                AppIcons.close,
                color: AppColors.textSecondary,
                size: 18,
              ),
              onPressed: () {
                controller!.clear();
                onClear?.call();
              },
            )
          : null,
    );
  }
}

/// Custom input formatter ensuring only digits are accepted, enforcing maxLength,
/// and allowing instant paste replacement even when the field is already full.
class _OtpInputFormatter extends TextInputFormatter {
  final int maxLength;

  _OtpInputFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Detect paste or AutoFill (more than 1 character added in a single edit)
    if (newDigits.length > oldDigits.length + 1) {
      String pastedDigits = newDigits;
      // If the field was already filled to maxLength and user pasted a new code,
      // extract the newly pasted digits cleanly.
      if (oldDigits.length == maxLength) {
        if (newDigits.startsWith(oldDigits)) {
          pastedDigits = newDigits.substring(oldDigits.length);
        } else if (newDigits.endsWith(oldDigits)) {
          pastedDigits = newDigits.substring(
            0,
            newDigits.length - oldDigits.length,
          );
        }
      }

      final result = pastedDigits.length > maxLength
          ? pastedDigits.substring(0, maxLength)
          : pastedDigits;

      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }

    // Normal typing or backspacing
    if (newDigits.length > maxLength) {
      final clamped = newDigits.substring(0, maxLength);
      return TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }

    return TextEditingValue(
      text: newDigits,
      selection: TextSelection.collapsed(offset: newDigits.length),
    );
  }
}

/// Production-grade OTP digit input field for AMOMY Auth verification.
/// Strictly input-only: never triggers auto-submission.
class AppOtpField extends StatefulWidget {
  final int length;
  final bool hasError;
  final bool isSuccess;
  final bool autoFocus;
  final void Function(String)? onCompleted;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const AppOtpField({
    super.key,
    this.length = 6,
    this.hasError = false,
    this.isSuccess = false,
    this.autoFocus = true,
    this.onCompleted,
    this.onChanged,
    this.controller,
    this.focusNode,
  });

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _successController;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isInternalController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasError && widget.hasError) {
      _shakeController.forward(from: 0.0);
      HapticFeedback.mediumImpact();
    }
    if (!oldWidget.isSuccess && widget.isSuccess) {
      _successController.forward(from: 0.0);
      HapticFeedback.mediumImpact();
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    widget.onChanged?.call(text);
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
    }
    // Auto-submission intentionally eliminated: completion ONLY enables the submit button.
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_isInternalController) _controller.dispose();
    if (_isInternalFocusNode) _focusNode.dispose();
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final isFocused = _focusNode.hasFocus;

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnimation, _successController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final spacing = (totalWidth < 360) ? 6.0 : 8.0;
          final cellWidth =
              ((totalWidth - (spacing * (widget.length - 1))) / widget.length)
                  .clamp(38.0, 52.0);
          final cellHeight = cellWidth * 1.22;

          return SizedBox(
            height: cellHeight,
            child: Stack(
              children: [
                // Visual OTP cells (touch events pass through to underlying TextField)
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(widget.length, (index) {
                      final isCellFilled = index < text.length;
                      final isCurrentCell =
                          isFocused &&
                          !widget.isSuccess &&
                          (index == text.length ||
                              (index == widget.length - 1 &&
                                  text.length == widget.length));
                      final char = isCellFilled ? text[index] : '';

                      // Staggered wave interval for cell [index] (40-70ms offset between cells)
                      final double startInterval = (index * 0.08).clamp(
                        0.0,
                        0.6,
                      );
                      final double endInterval = (startInterval + 0.45).clamp(
                        0.0,
                        1.0,
                      );
                      final double cellProgress = widget.isSuccess
                          ? Interval(
                              startInterval,
                              endInterval,
                              curve: Curves.easeOutCubic,
                            ).transform(_successController.value)
                          : 0.0;

                      Color borderColor = AppColors.border;
                      Color bgColor = Colors.white;
                      Color textColor = AppColors.primary;
                      double borderWidth = 1.0;

                      if (widget.hasError) {
                        borderColor = AppColors.error;
                        borderWidth = 1.5;
                        bgColor = AppColors.errorLight.withValues(alpha: 0.15);
                        textColor = AppColors.error;
                      } else if (isCurrentCell) {
                        borderColor = AppColors.primary;
                        borderWidth = 2.0;
                        bgColor = AppColors.primaryLight.withValues(
                          alpha: 0.35,
                        );
                        textColor = AppColors.primary;
                      } else if (isCellFilled) {
                        borderColor = AppColors.primary;
                        borderWidth = 1.5;
                        bgColor = Colors.white;
                        textColor = AppColors.primary;
                      }

                      if (widget.isSuccess && cellProgress > 0.0) {
                        borderColor = Color.lerp(
                          borderColor,
                          AppColors.success,
                          cellProgress,
                        )!;
                        bgColor = Color.lerp(
                          bgColor,
                          AppColors.success,
                          cellProgress,
                        )!;
                        textColor = Color.lerp(
                          textColor,
                          Colors.white,
                          cellProgress,
                        )!;
                        borderWidth = 1.5;
                      }

                      final scale = widget.isSuccess && cellProgress > 0.0
                          ? 1.0 + (math.sin(cellProgress * math.pi) * 0.08)
                          : 1.0;

                      return Transform.scale(
                        scale: scale,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: cellWidth,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: borderWidth,
                            ),
                            boxShadow: widget.isSuccess && cellProgress > 0.0
                                ? [
                                    BoxShadow(
                                      color: AppColors.success.withValues(
                                        alpha: 0.25 * cellProgress,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : isCurrentCell
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Text(
                              char,
                              key: ValueKey<String>('$index-$char'),
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Transparent, fully stretched TextField ensuring native iOS AutoFill, paste, and tap
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableSuggestions: false,
                      inputFormatters: [_OtpInputFormatter(widget.length)],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
