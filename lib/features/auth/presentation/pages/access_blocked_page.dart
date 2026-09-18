import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class AccessBlockedPage extends StatelessWidget {
  final AccessBlockedType type;
  final DateTime? bannedUntil;
  final String? customMessage;

  const AccessBlockedPage({
    super.key,
    required this.type,
    this.bannedUntil,
    this.customMessage,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final String message;
    if (customMessage != null && customMessage!.isNotEmpty) {
      message = customMessage!;
    } else {
      switch (type) {
        case AccessBlockedType.deviceBlocked:
          message = l10n.deviceBlockedMessage;
          break;
        case AccessBlockedType.permanentBan:
          message = l10n.accountSuspendedMessage;
          break;
        case AccessBlockedType.temporaryBan:
          message = l10n.accountSuspendedUntilMessage(_formatDate(bannedUntil));
          break;
      }
    }

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: AppColors.error,
                      size: 44,
                    ),
                  ),
                  AppSpacing.gapH24,
                  Text(
                    l10n.accessBlockedTitle,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH12,
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH32,
                  AppButton(
                    label: l10n.retry,
                    isFullWidth: true,
                    onPressed: () {
                      context.read<AuthBloc>().add(const AuthCheckRequested());
                    },
                  ),
                  if (type != AccessBlockedType.deviceBlocked) ...[
                    AppSpacing.gapH12,
                    AppButton(
                      label: l10n.logout,
                      variant: AppButtonVariant.outline,
                      isFullWidth: true,
                      onPressed: () {
                        context.read<AuthBloc>().add(const SignOutRequested());
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
