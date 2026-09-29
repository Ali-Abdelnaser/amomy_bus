import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../data/datasources/referral_remote_data_source.dart';
import '../../data/repositories/referral_repository_impl.dart';
import '../../domain/repositories/referral_repository.dart';
import '../../domain/usecases/referral_usecases.dart';
import '../cubit/referral_cubit.dart';
import '../cubit/referral_state.dart';
import '../widgets/my_referrals_tab.dart';
import '../widgets/who_invited_me_tab.dart';

/// Passenger Invite Friends Page
///
/// Provides two tabs:
/// 1. "دعواتي" (My Invites): referral code, copy, share, QR, monthly progress, total points, friends progress.
/// 2. "من دعاني" (Who Invited Me): preview code, inviter info, confirmation before binding, or linked progress.
class InviteFriendsPage extends StatefulWidget {
  final String? initialCode;
  final ReferralCubit? referralCubit;

  const InviteFriendsPage({
    super.key,
    this.initialCode,
    this.referralCubit,
  });

  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ReferralCubit _cubit;
  bool _createdCubitLocally = false;

  void _redirectDisabled(BuildContext context) {
    if (!mounted) return;
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(RoutePaths.home);
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final hasInitialCode =
        widget.initialCode != null && widget.initialCode!.trim().isNotEmpty;

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: hasInitialCode ? 1 : 0,
    );

    if (widget.referralCubit != null) {
      _cubit = widget.referralCubit!;
    } else if (getIt.isRegistered<ReferralCubit>()) {
      _cubit = getIt<ReferralCubit>();
    } else {
      _createdCubitLocally = true;
      final repo = getIt.isRegistered<ReferralRepository>()
          ? getIt<ReferralRepository>()
          : ReferralRepositoryImpl(
              remoteDataSource: getIt.isRegistered<ReferralRemoteDataSource>()
                  ? getIt<ReferralRemoteDataSource>()
                  : ReferralRemoteDataSourceImpl(),
            );
      _cubit = ReferralCubit(
        getDashboardUseCase: GetMyReferralDashboardUseCase(repo),
        previewCodeUseCase: PreviewReferralCodeUseCase(repo),
        bindCodeUseCase: BindReferralCodeUseCase(repo),
        repository: repo,
      );
    }

    _cubit.startListeningToDashboardUpdates();
    _cubit.loadDashboard();

    if (_cubit.state.status == ReferralStatus.loaded &&
        _cubit.state.isProgramDisabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectDisabled(context);
      });
    }
  }

  @override
  void didUpdateWidget(covariant InviteFriendsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCode != null &&
        widget.initialCode != oldWidget.initialCode &&
        widget.initialCode!.trim().isNotEmpty) {
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_createdCubitLocally) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ReferralCubit, ReferralState>(
        listener: (context, state) {
          if (state.status == ReferralStatus.loaded &&
              state.isProgramDisabled) {
            _redirectDisabled(context);
          }
        },
        builder: (context, state) {
          if (state.isProgramDisabled) {
            return const SizedBox.shrink();
          }

          return AppScaffold(
            appBar: AppAppBar(
              title: isAr ? 'ادعُ أصدقاءك' : 'Invite Friends',
              showBackButton: true,
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: AppTextStyles.labelLarge,
                tabs: [
                  Tab(text: isAr ? 'دعواتي' : 'My Invites'),
                  Tab(text: isAr ? 'من دعاني' : 'Who Invited Me'),
                ],
              ),
            ),
            body: _buildBody(context, state, isAr),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReferralState state, bool isAr) {
    if (state.status == ReferralStatus.loading &&
        state.dashboard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            AppSpacing.gapH16,
            Text(
              isAr
                  ? 'جاري تحميل برنامج الدعوات...'
                  : 'Loading referral program...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == ReferralStatus.error &&
        state.dashboard == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.info,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              AppSpacing.gapH16,
              Text(
                isAr
                    ? 'تعذر تحميل بيانات الدعوات'
                    : 'Failed to load invites data',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                state.errorMessage ??
                    (isAr
                        ? 'حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة مرة أخرى.'
                        : 'An error occurred while connecting. Please try again.'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapH24,
              AppButton(
                text: isAr ? 'إعادة المحاولة' : 'Retry',
                onPressed: () => _cubit.loadDashboard(isRefresh: true),
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),
      );
    }

    final dashboard = state.dashboard;
    if (dashboard == null) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        MyReferralsTab(
          dashboard: dashboard,
          onRefresh: () => _cubit.loadDashboard(isRefresh: true),
        ),
        WhoInvitedMeTab(
          dashboard: dashboard,
          initialCode: widget.initialCode,
        ),
      ],
    );
  }
}
