import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            context.read<AuthBloc>().add(const AuthCheckRequested());
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
              // 1. Subtle background splash composition asset
              Positioned.fill(
                child: Opacity(
                  opacity: 0.10,
                  child: Image.asset(
                    AppAssets.splash,
                    fit: BoxFit.cover,
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms),

              // 2. Centralized Logo & Branding Experience
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Transparent logo with smooth scale-in and fade-in
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Image.asset(
                          AppAssets.logoTransparent,
                          fit: BoxFit.contain,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),

                      AppSpacing.gapH24,

                      // App Name
                      Text(
                        context.l10n.appName,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0, duration: 500.ms),

                      AppSpacing.gapH8,

                      // Version Indicator
                      Text(
                        'v${AppConstants.appVersion}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                      AppSpacing.gapH32,

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
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                    ],
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
