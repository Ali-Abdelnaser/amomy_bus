import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_event.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SplashBloc>()..add(const SplashCheckRequested()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashLoaded) {
            if (!state.status.isOnboardingCompleted) {
              context.go('/onboarding');
            } else {
              context.read<AuthBloc>().add(const AuthCheckRequested());
            }
          }
        },
        builder: (context, state) {
          if (state is SplashError) {
            return AppErrorView(
              message: state.failure.message,
              onRetry: () =>
                  context.read<SplashBloc>().add(const SplashCheckRequested()),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final logoSize = (constraints.maxWidth * 0.78).clamp(
                        280.0,
                        420.0,
                      );

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Matches the native launch image so the first Flutter frame
                          // continues the same white AMOMY splash without a visual jump.
                          SizedBox.square(
                            dimension: logoSize,
                            child: Image.asset(
                              AppAssets.splash,
                              fit: BoxFit.contain,
                            ),
                          ),

                          AppSpacing.gapH12,

                          // App Name
                          Text(
                            context.l10n.appName,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ).animate().fadeIn(delay: 250.ms, duration: 450.ms),

                          AppSpacing.gapH8,

                          // Version Indicator
                          Text(
                            'v${AppConstants.appVersion}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ).animate().fadeIn(delay: 350.ms, duration: 350.ms),

                          AppSpacing.gapH24,

                          // Subtle Circular Brand Indicator
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              backgroundColor: AppColors.primaryLight,
                            ),
                          ).animate().fadeIn(delay: 450.ms, duration: 350.ms),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
