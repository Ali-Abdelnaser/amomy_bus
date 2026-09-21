import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/error/app_error_mapper.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../topup/domain/entities/topup_entities.dart';
import '../../../topup/presentation/cubit/topup_history_cubit.dart';
import '../../../topup/presentation/cubit/topup_history_state.dart';
import '../../domain/entities/wallet_history_event.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/wallet_card_widget.dart';
import '../widgets/wallet_history_event_tile.dart';
import '../widgets/wallet_pending_points_section.dart';
import '../widgets/wallet_points_summary_card.dart';
import '../widgets/wallet_transaction_tile.dart';

class WalletPage extends StatefulWidget {
  final WalletCubit? walletCubit;
  final TopUpHistoryCubit? topUpHistoryCubit;

  const WalletPage({super.key, this.walletCubit, this.topUpHistoryCubit});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _cardFadeAnim;
  late final Animation<Offset> _cardSlideAnim;
  late final Animation<double> _contentFadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _cardFadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _cardSlideAnim =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    _contentFadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAddPoints(BuildContext context, String userId) async {
    final availablePoints = context
        .read<WalletCubit>()
        .state
        .summary
        .totalAvailablePoints;
    await context.push(RoutePaths.addPoints, extra: availablePoints);
    if (context.mounted && userId.isNotEmpty) {
      context.read<WalletCubit>().loadWalletSummary(userId);
      context.read<TopUpHistoryCubit>().loadRequests();
    }
  }

  Future<void> _navigateToResubmit(
    BuildContext context,
    TopUpRequest request,
    String userId,
  ) async {
    await context.push(RoutePaths.addPoints, extra: request);
    if (context.mounted && userId.isNotEmpty) {
      context.read<WalletCubit>().loadWalletSummary(userId);
      context.read<TopUpHistoryCubit>().loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final disableAnim = MediaQuery.of(context).disableAnimations;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = authState is Authenticated ? authState.user.id : '';

        final parentWalletCubit =
            widget.walletCubit ??
            () {
              try {
                return context.read<WalletCubit>();
              } catch (_) {
                return null;
              }
            }();

        return MultiBlocProvider(
          providers: [
            if (parentWalletCubit != null)
              BlocProvider<WalletCubit>.value(value: parentWalletCubit)
            else
              BlocProvider<WalletCubit>(
                create: (context) => getIt.isRegistered<WalletCubit>()
                    ? (getIt<WalletCubit>()..loadWalletSummary(userId))
                    : WalletCubit.idle(),
              ),
            BlocProvider(
              create: (context) {
                final cubit =
                    widget.topUpHistoryCubit ??
                    (getIt.isRegistered<TopUpHistoryCubit>()
                        ? (getIt<TopUpHistoryCubit>()
                            ..loadRequests()
                            ..startListeningToUpdates())
                        : TopUpHistoryCubit.idle());
                cubit.onApprovedTopUpDetected = () {
                  if (context.mounted && userId.isNotEmpty) {
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
                  final isError = walletState.status == WalletStatus.error;
                  final summary = walletState.summary;
                  final fallbackWallet = authState is Authenticated
                      ? authState.wallet
                      : null;

                  // Authoritative single points balance from backend/state
                  final totalPoints = walletState.status == WalletStatus.loaded
                      ? summary.totalAvailablePoints
                      : (fallbackWallet?.availablePoints ??
                            fallbackWallet?.totalPoints ??
                            0);

                  return Scaffold(
                    backgroundColor: AppColors.background,
                    body: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // 1. TOP APP BAR: Matching "My Trips" Style & Hierarchy
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: SizedBox(
                              height: 48,
                              child: Center(
                                child: Text(
                                  isAr ? 'المحفظة' : 'Wallet',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF101828),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 2. MAIN SCROLLABLE CONTENT
                          Expanded(
                            child:
                                isError &&
                                    walletState.summary.totalAvailablePoints ==
                                        0
                                ? _buildErrorView(context, userId, walletState)
                                : RefreshIndicator(
                                    onRefresh: () async {
                                      if (userId.isNotEmpty) {
                                        await Future.wait([
                                          context
                                              .read<WalletCubit>()
                                              .loadWalletSummary(userId),
                                          context
                                              .read<TopUpHistoryCubit>()
                                              .loadRequests(),
                                        ]);
                                      }
                                    },
                                    child: Skeletonizer(
                                      enabled: isLoading,
                                      child: SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            // A. Hero Wallet Card: Wide, almost full width
                                            disableAnim
                                                ? const WalletCardWidget()
                                                : FadeTransition(
                                                    opacity: _cardFadeAnim,
                                                    child: SlideTransition(
                                                      position: _cardSlideAnim,
                                                      child:
                                                          const WalletCardWidget(),
                                                    ),
                                                  ),

                                            AppSpacing.gapH16,

                                            // B. Separate Secondary Points Summary Card
                                            disableAnim
                                                ? WalletPointsSummaryCard(
                                                    points: totalPoints,
                                                    onAddPoints: () =>
                                                        _navigateToAddPoints(
                                                          context,
                                                          userId,
                                                        ),
                                                  )
                                                : FadeTransition(
                                                    opacity: _contentFadeAnim,
                                                    child: WalletPointsSummaryCard(
                                                      points: totalPoints,
                                                      onAddPoints: () =>
                                                          _navigateToAddPoints(
                                                            context,
                                                            userId,
                                                          ),
                                                    ),
                                                  ),

                                            // C. Pending / Rejected Top-Ups Section
                                            BlocBuilder<
                                              TopUpHistoryCubit,
                                              TopUpHistoryState
                                            >(
                                              builder: (context, historyState) {
                                                final requests =
                                                    walletState
                                                        .topUpRequests
                                                        .isNotEmpty
                                                    ? walletState.topUpRequests
                                                    : historyState.requests;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 14,
                                                      ),
                                                  child:
                                                      WalletPendingPointsSection(
                                                        requests: requests,
                                                        onResubmit: (req) =>
                                                            _navigateToResubmit(
                                                              context,
                                                              req,
                                                              userId,
                                                            ),
                                                      ),
                                                );
                                              },
                                            ),

                                            AppSpacing.gapH24,

                                            // D. Recent Transactions Header
                                            disableAnim
                                                ? _buildTransactionsHeader(
                                                    context,
                                                  )
                                                : FadeTransition(
                                                    opacity: _contentFadeAnim,
                                                    child:
                                                        _buildTransactionsHeader(
                                                          context,
                                                        ),
                                                  ),

                                            const SizedBox(height: 12),

                                            // E. Transactions List or Empty State
                                            disableAnim
                                                ? _buildTransactionsContent(
                                                    context,
                                                    isLoading,
                                                    walletState,
                                                  )
                                                : FadeTransition(
                                                    opacity: _contentFadeAnim,
                                                    child:
                                                        _buildTransactionsContent(
                                                          context,
                                                          isLoading,
                                                          walletState,
                                                        ),
                                                  ),

                                            AppSpacing.gapBottomNav,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
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

  Widget _buildTransactionsHeader(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.recentTransactions,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF101828),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsContent(
    BuildContext context,
    bool isLoading,
    WalletState walletState,
  ) {
    final l10n = context.l10n;
    final historyEvents = walletState.historyEvents;
    final legacyTransactions = walletState.transactions;

    // Loading skeleton placeholder items
    if (isLoading && historyEvents.isEmpty && legacyTransactions.isEmpty) {
      return Column(
        children: List.generate(
          4,
          (index) => WalletHistoryEventTile(
            event: WalletHistoryEvent(
              eventId: 'skeleton_$index',
              semanticType: index.isEven
                  ? WalletSemanticType.tripBooking
                  : WalletSemanticType.pointsTopup,
              signedAmount: index.isEven ? -25 : 300,
              createdAt: DateTime.now(),
            ),
          ),
        ),
      );
    }

    // Clean Empty State
    if (historyEvents.isEmpty && legacyTransactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4EBF2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.receipt,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              AppSpacing.gapH16,
              Text(
                l10n.noTransactionsTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH8,
              Text(
                l10n.noTransactionsSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Semantic History List (preferred) or Legacy Transactions fallback
    final bool useSemantic = historyEvents.isNotEmpty;
    final int itemCount = useSemantic
        ? historyEvents.length + (walletState.hasMoreHistory ? 1 : 0)
        : legacyTransactions.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 0.75, color: Color(0xFFF2F4F7)),
        itemBuilder: (context, index) {
          if (useSemantic) {
            if (index == historyEvents.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: walletState.isLoadingMoreHistory
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () {
                            context.read<WalletCubit>().loadMoreHistory();
                          },
                          child: Text(
                            l10n.loadMoreTransactions,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              );
            }
            final event = historyEvents[index];
            return WalletHistoryEventTile(event: event);
          } else {
            final tx = legacyTransactions[index];
            return WalletTransactionTile(transaction: tx);
          }
        },
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    String userId,
    WalletState walletState,
  ) {
    final message = AppErrorMapper.map(
      context,
      walletState.errorFailure ?? walletState.errorMessage,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            AppSpacing.gapH16,
            Text(
              context.l10n.errorGeneric,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH8,
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH24,
            ElevatedButton(
              onPressed: () {
                if (userId.isNotEmpty) {
                  context.read<WalletCubit>().loadWalletSummary(userId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
