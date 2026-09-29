import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Clean destructive confirmation bottom sheet for self account deletion.
class DeleteAccountBottomSheet extends StatefulWidget {
  final String currentEmail;
  final Future<String?> Function()? appleReauthProvider;

  const DeleteAccountBottomSheet({
    super.key,
    required this.currentEmail,
    this.appleReauthProvider,
  });

  @override
  State<DeleteAccountBottomSheet> createState() =>
      _DeleteAccountBottomSheetState();
}

class _DeleteAccountBottomSheetState extends State<DeleteAccountBottomSheet> {
  late final TextEditingController _emailController;
  bool _isAppleReauthenticating = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isEmailMatching {
    final entered = _emailController.text.trim().toLowerCase();
    final target = widget.currentEmail.trim().toLowerCase();
    return entered.isNotEmpty && entered == target;
  }

  Future<void> _handleDeleteTapped(bool isAr) async {
    final profileBloc = context.read<ProfileBloc>();
    final confirmed = await showAppDialog<bool>(
      context: context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.warning,
              color: AppColors.error,
              size: 28,
            ),
          ),
          AppSpacing.gapH16,
          Text(
            isAr
                ? 'هل أنت متأكد من حذف حسابك نهائيًا؟'
                : 'Are you sure you want to permanently delete your account?',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH8,
          Text(
            isAr
                ? 'سيتم حذف جميع بياناتك وسجل رحلاتك فورًا ولن تتمكن من استعادة الحساب.'
                : 'All your account data and bookings will be removed immediately and cannot be recovered.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
            ),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              isAr ? 'تأكيد الحذف' : 'Confirm Delete',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );

    if (confirmed == true && mounted) {
      final email = _emailController.text.trim();

      if (profileBloc.repository.isAppleUser) {
        setState(() => _isAppleReauthenticating = true);
        String? authCode;
        try {
          if (widget.appleReauthProvider != null) {
            authCode = await widget.appleReauthProvider!();
          } else {
            final credential = await SignInWithApple.getAppleIDCredential(
              scopes: [AppleIDAuthorizationScopes.email],
            );
            authCode = credential.authorizationCode;
          }
        } catch (e) {
          if (!mounted) return;
          setState(() => _isAppleReauthenticating = false);

          final errStr = e.toString();
          final isCancel = (e is SignInWithAppleAuthorizationException &&
                  e.code == AuthorizationErrorCode.canceled) ||
              errStr.contains('AuthorizationErrorCode.canceled') ||
              errStr.contains('ASAuthorizationErrorCanceled') ||
              errStr.contains('canceled') ||
              errStr.contains('cancelled') ||
              errStr.contains('1000');

          if (isCancel) {
            AppSnackBar.showWarning(
              context,
              isAr
                  ? 'تم إلغاء التحقق بواسطة Apple ولم يتم حذف الحساب.'
                  : 'Apple re-authentication was cancelled. Account was not deleted.',
            );
          } else {
            AppSnackBar.showError(
              context,
              isAr
                  ? 'تعذر التحقق من هوية Apple. حاول مرة أخرى.'
                  : 'Failed to verify Apple identity. Please try again.',
            );
          }
          return;
        }

        if (!mounted) return;
        setState(() => _isAppleReauthenticating = false);

        if (authCode == null || authCode.isEmpty) {
          AppSnackBar.showError(
            context,
            isAr
                ? 'رمز تفويض Apple مطلوب لإتمام الحذف.'
                : 'Apple authorization code is required to complete account deletion.',
          );
          return;
        }

        profileBloc.add(
          ProfileDeleteAccountRequested(
            confirmationEmail: email,
            authorizationCode: authCode,
          ),
        );
      } else {
        profileBloc.add(
          ProfileDeleteAccountRequested(
            confirmationEmail: email,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileDeleteAccountSuccess) {
          final authBloc = context.read<AuthBloc>();
          authBloc.add(const SignOutRequested());
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else if (state is ProfileDeleteAccountFailure) {
          AppSnackBar.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading =
            state is ProfileDeleteAccountLoading || _isAppleReauthenticating;

        return AmomySheetContainer(
          hasBottomNav: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Destructive icon header
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.trash,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),
                AppSpacing.gapH16,

                // Title
                Text(
                  isAr ? 'حذف الحساب نهائيًا' : 'Delete Account Permanently',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH12,

                // Clear explanation card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(
                      color: const Color(0xFFFECDCA),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            AppIcons.warning,
                            color: AppColors.error,
                            size: 18,
                          ),
                          AppSpacing.gapW8,
                          Text(
                            isAr ? 'تنبيه هام ومصيري:' : 'Important notice:',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      _buildBulletPoint(
                        isAr
                            ? 'سيتم حذف حسابك وجميع بياناتك الشخصية نهائيًا.'
                            : 'Your account and personal data will be permanently deleted.',
                      ),
                      AppSpacing.gapH4,
                      _buildBulletPoint(
                        isAr
                            ? 'سيتم إلغاء وإزالة سجل الحجوزات والمعاملات المرتبطة بحسابك.'
                            : 'All your bookings and transaction history will be removed.',
                      ),
                      AppSpacing.gapH4,
                      _buildBulletPoint(
                        isAr
                            ? 'هذا الإجراء نهائي ولا يمكن التراجع عنه أبدًا.'
                            : 'This action is permanent and cannot be undone.',
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH16,

                // Current account email section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: const Color(0xFFE5E9F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'البريد الإلكتروني الحالي للحساب:'
                            : 'Current Account Email:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppSpacing.gapH4,
                      SelectableText(
                        widget.currentEmail,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH16,

                // Confirmation input prompt
                Text(
                  isAr
                      ? 'اكتب بريدك الإلكتروني للتأكيد:'
                      : 'Type your email to confirm:',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapH8,

                TextField(
                  controller: _emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: widget.currentEmail,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                      borderSide: BorderSide(
                        color: _isEmailMatching
                            ? AppColors.error
                            : AppColors.border,
                        width: _isEmailMatching ? 1.5 : 1,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapH24,

                // Buttons: Cancel & Red Delete Button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          isAr ? 'إلغاء' : 'Cancel',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isEmailMatching && !isLoading)
                            ? () => _handleDeleteTapped(isAr)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          disabledBackgroundColor: const Color(0xFFFECDCA),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMd,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                isAr ? 'حذف الحساب' : 'Delete Account',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF912018),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
