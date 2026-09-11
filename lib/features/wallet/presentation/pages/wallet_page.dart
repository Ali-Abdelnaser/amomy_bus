import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../topup/presentation/cubit/topup_history_cubit.dart';
import '../../../topup/presentation/cubit/topup_history_state.dart';
import '../../../topup/presentation/widgets/topup_history_section.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';

class WalletPage extends StatelessWidget {
  final WalletCubit? walletCubit;
  final TopUpHistoryCubit? topUpHistoryCubit;

  const WalletPage({
    super.key,
    this.walletCubit,
    this.topUpHistoryCubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = NumberFormat('#,###');

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = authState is Authenticated ? authState.user.id : '';

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => walletCubit ??
                  (getIt.isRegistered<WalletCubit>()
                      ? (getIt<WalletCubit>()..loadWalletSummary(userId))
                      : WalletCubit.idle()),
            ),
            BlocProvider(
              create: (context) {
                final cubit = topUpHistoryCubit ??
                    (getIt.isRegistered<TopUpHistoryCubit>()
                        ? (getIt<TopUpHistoryCubit>()
                          ..loadRequests()
                          ..startListeningToUpdates())
                        : TopUpHistoryCubit.idle());
                cubit.onApprovedTopUpDetected = () {
                  if (context.mounted) {
                    context.read<WalletCubit>().loadWalletSummary(userId);
                  }
                };
                return cubit;
              },
            ),
          ],
          child: Builder(
            builder: (innerContext) {
              return BlocBuilder<WalletCubit, WalletState>(
                builder: (context, walletState) {
                  final isLoading = walletState.status == WalletStatus.loading;
                  final summary = walletState.summary;
                  final fallbackWallet = authState is Authenticated ? authState.wallet : null;

                  final totalPoints = walletState.status == WalletStatus.loaded
                      ? summary.totalAvailablePoints
                      : (fallbackWallet?.availablePoints ?? fallbackWallet?.totalPoints ?? 0);
                  final cashPoints = walletState.status == WalletStatus.loaded
                      ? summary.cashPoints
                      : (fallbackWallet?.cashPoints ?? 0);
                  final subscriptionPoints = walletState.status == WalletStatus.loaded
                      ? summary.subscriptionPoints
                      : (fallbackWallet?.subscriptionPoints ?? 0);

                  return AppScaffold(
                    appBar: AppAppBar(
                      title: l10n.navWallet,
                      showBackButton: false,
                    ),
                    body: SafeArea(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await Future.wait([
                            context.read<WalletCubit>().loadWalletSummary(userId),
                            context.read<TopUpHistoryCubit>().loadRequests(),
                          ]);
                        },
                        child: Skeletonizer(
                          enabled: isLoading,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Main Points Hero Card
                                AppCard(
                                  padding: AppSpacing.edgeInsetsA24,
                                  backgroundColor: AppColors.primary,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.pointsBalance,
                                         style: AppTextStyles.labelMedium.copyWith(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      AppSpacing.gapH8,
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            formatter.format(totalPoints),
                                            style: AppTextStyles.headlineLarge.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 36,
                                            ),
                                          ),
                                          AppSpacing.gapW8,
                                          Text(
                                            l10n.pointsUnit,
                                            style: AppTextStyles.titleMedium.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      AppSpacing.gapH24,
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await context.push(RoutePaths.addPoints);
                                          if (context.mounted) {
                                            context.read<WalletCubit>().loadWalletSummary(userId);
                                            context.read<TopUpHistoryCubit>().loadRequests();
                                          }
                                        },
                                        icon: const Icon(AppIcons.add, size: 18, color: AppColors.primary),
                                        label: Text(
                                          l10n.addPoints,
                                          style: AppTextStyles.labelLarge.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.gapH20,

                                // Points Breakdown Tiles
                                Row(
                                  children: [
                                    // Cash Points Tile
                                    Expanded(
                                      child: AppCard(
                                        padding: AppSpacing.edgeInsetsA16,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                AppSpacing.gapW8,
                                                Flexible(
                                                  child: Text(
                                                    l10n.cashPointsPrefix,
                                                    style: AppTextStyles.labelSmall.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            AppSpacing.gapH8,
                                            Text(
                                              formatter.format(cashPoints),
                                              style: AppTextStyles.headlineMedium.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AppSpacing.gapW12,

                                    // Subscription Points Tile
                                    Expanded(
                                      child: AppCard(
                                        padding: AppSpacing.edgeInsetsA16,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.accentYellow,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                AppSpacing.gapW8,
                                                Flexible(
                                                  child: Text(
                                                    l10n.subscriptionPointsPrefix,
                                                    style: AppTextStyles.labelSmall.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            AppSpacing.gapH8,
                                            Text(
                                              formatter.format(subscriptionPoints),
                                              style: AppTextStyles.headlineMedium.copyWith(
                                                color: const Color(0xFFB57D00),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapH24,

                                // Top-Up Requests Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.topUpHistoryTitle,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await context.push(RoutePaths.addPoints);
                                        if (context.mounted) {
                                          context.read<WalletCubit>().loadWalletSummary(userId);
                                          context.read<TopUpHistoryCubit>().loadRequests();
                                        }
                                      },
                                      child: Text(
                                        l10n.addPoints,
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapH8,

                                BlocBuilder<TopUpHistoryCubit, TopUpHistoryState>(
                                  builder: (context, historyState) {
                                    return TopUpHistorySection(
                                      requests: historyState.requests,
                                      isLoading: historyState.isLoading,
                                    );
                                  },
                                ),
                                AppSpacing.gapH24,

                                // Transactions Section
                                Text(
                                  l10n.transactions,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                AppSpacing.gapH12,

                                // Clean empty state for transactions
                                AppCard(
                                  padding: AppSpacing.edgeInsetsA24,
                                  child: AppEmptyView(
                                    icon: AppIcons.receipt,
                                    message: l10n.noTransactionsSubtitle,
                                  ),
                                ),
                                AppSpacing.gapBottomNav,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
