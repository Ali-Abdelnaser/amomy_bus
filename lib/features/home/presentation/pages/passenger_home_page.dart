import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../widgets/home_booking_cta.dart';
import '../widgets/home_header.dart';
import '../widgets/home_profile_completion_card.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_upcoming_trip_section.dart';
import '../widgets/home_wallet_card.dart';

class PassengerHomePage extends StatelessWidget {
  final WalletCubit? walletCubit;

  const PassengerHomePage({
    super.key,
    this.walletCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return AppScaffold(
            body: SafeArea(
              child: Skeletonizer(
                enabled: true,
                child: SingleChildScrollView(
                  padding: AppSpacing.edgeInsetsA20,
                  child: Column(
                    children: [
                      Container(height: 50, color: AppColors.surfaceSoft),
                      AppSpacing.gapH20,
                      Container(height: 140, color: AppColors.surfaceSoft),
                      AppSpacing.gapH20,
                      Container(height: 160, color: AppColors.surfaceSoft),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final user = authState.user;

        return BlocProvider(
          create: (context) => walletCubit ?? (getIt.isRegistered<WalletCubit>() ? (getIt<WalletCubit>()..loadWalletSummary(user.id)) : WalletCubit.idle()),
          child: AppScaffold(
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. Header
                  HomeHeader(user: user).appFadeIn(),
                  AppSpacing.gapH20,

                  // B. Profile Completion Card (Conditional)
                  if (!user.isProfileComplete) ...[
                    HomeProfileCompletionCard(user: user).appSlideUp(
                      delay: const Duration(milliseconds: 50),
                    ),
                    AppSpacing.gapH20,
                  ],

                  // C. Wallet / Points Card (With its own cubit & error resilience)
                  BlocBuilder<WalletCubit, WalletState>(
                    builder: (context, walletState) {
                      final isLoading = walletState.status == WalletStatus.loading;
                      final summary = walletState.summary;
                      // Graceful fallback: use authState.wallet if WalletCubit is initial/failed
                      final total = walletState.status == WalletStatus.loaded
                          ? summary.totalAvailablePoints
                          : (authState.wallet?.availablePoints ?? authState.wallet?.totalPoints ?? 0);
                      final cash = walletState.status == WalletStatus.loaded
                          ? summary.cashPoints
                          : (authState.wallet?.cashPoints ?? 0);
                      final sub = walletState.status == WalletStatus.loaded
                          ? summary.subscriptionPoints
                          : (authState.wallet?.subscriptionPoints ?? 0);

                      return Skeletonizer(
                        enabled: isLoading,
                        child: HomeWalletCard(
                          totalPoints: total,
                          cashPoints: cash,
                          subscriptionPoints: sub,
                          isLoading: isLoading,
                        ),
                      ).appSlideUp(
                        delay: const Duration(milliseconds: 100),
                      );
                    },
                  ),
                  AppSpacing.gapH20,

                  // D. Primary Booking CTA
                  const HomeBookingCta().appSlideUp(
                    delay: const Duration(milliseconds: 150),
                  ),
                  AppSpacing.gapH24,

                  // E. Upcoming Trip Section
                  const HomeUpcomingTripSection().appSlideUp(
                    delay: const Duration(milliseconds: 200),
                  ),
                  AppSpacing.gapH24,

                  // F. Quick Actions
                  const HomeQuickActions().appSlideUp(
                    delay: const Duration(milliseconds: 250),
                  ),
                  AppSpacing.gapBottomNav,
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
