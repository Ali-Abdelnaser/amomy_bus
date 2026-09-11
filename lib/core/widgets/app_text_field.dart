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
      prefixIcon: const Icon(AppIcons.search, color: AppColors.textSecondary, size: 20),
      suffixIcon: controller != null && controller!.text.isNotEmpty
          ? IconButton(
              icon: const Icon(AppIcons.close, color: AppColors.textSecondary, size: 18),
              onPressed: () {
                controller!.clear();
                onClear?.call();
              },
            )
          : null,
    );
  }
}

/// OTP digit input field placeholder/foundation for Auth OTP verification
class AppOtpField extends StatelessWidget {
  final int length;
  final void Function(String)? onCompleted;
  final void Function(String)? onChanged;

  const AppOtpField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        length,
        (index) => SizedBox(
          width: 44,
          height: 52,
          child: TextFormField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
            decoration: const InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && index < length - 1) {
                FocusScope.of(context).nextFocus();
              }
              onChanged?.call(value);
            },
          ),
        ),
      ),
    );
  }
}
