import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../cubit/passenger_trips_cubit.dart';
import '../cubit/passenger_trips_state.dart';
import '../widgets/trip_booking_card.dart';

class MyTripsPage extends StatelessWidget {
  final PassengerTripsCubit? tripsCubit;

  const MyTripsPage({super.key, this.tripsCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => tripsCubit ?? (getIt.isRegistered<PassengerTripsCubit>() ? (getIt<PassengerTripsCubit>()..loadBookings()) : PassengerTripsCubit.idle()),
      child: const _MyTripsContent(),
    );
  }
}

class _MyTripsContent extends StatefulWidget {
  const _MyTripsContent();

  @override
  State<_MyTripsContent> createState() => _MyTripsContentState();
}

class _MyTripsContentState extends State<_MyTripsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.navMyTrips,
        showBackButton: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: l10n.upcomingTab),
                Tab(text: l10n.historyTab),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<PassengerTripsCubit, PassengerTripsState>(
        builder: (context, state) {
          if (state.status == PassengerTripsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming Tab
              state.upcomingTrips.isEmpty
                  ? AppEmptyView(
                      icon: AppIcons.bus,
                      message: l10n.noUpcomingTrip,
                      action: AppButton(
                        label: l10n.bookTripCta,
                        icon: AppIcons.ticket,
                        onPressed: () => context.push('/book-trip'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => context.read<PassengerTripsCubit>().loadBookings(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s20,
                          AppSpacing.s20,
                          AppSpacing.s20,
                          AppSpacing.bottomNavClearance,
                        ),
                        itemCount: state.upcomingTrips.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return TripBookingCard(booking: state.upcomingTrips[index]);
                        },
                      ),
                    ),

              // History Tab
              state.pastTrips.isEmpty
                  ? AppEmptyView(
                      icon: AppIcons.calendar,
                      message: l10n.noTripsSubtitle,
                    )
                  : RefreshIndicator(
                      onRefresh: () => context.read<PassengerTripsCubit>().loadBookings(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s20,
                          AppSpacing.s20,
                          AppSpacing.s20,
                          AppSpacing.bottomNavClearance,
                        ),
                        itemCount: state.pastTrips.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return TripBookingCard(booking: state.pastTrips[index]);
                        },
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
