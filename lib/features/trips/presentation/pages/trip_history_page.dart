import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_loading.dart';
import '../cubit/passenger_trips_cubit.dart';
import '../cubit/passenger_trips_state.dart';
import '../widgets/trip_history_card.dart';

class TripHistoryPage extends StatelessWidget {
  final PassengerTripsCubit? tripsCubit;

  const TripHistoryPage({super.key, this.tripsCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          tripsCubit ??
          (getIt.isRegistered<PassengerTripsCubit>()
              ? (getIt<PassengerTripsCubit>()..loadTripsHub())
              : PassengerTripsCubit.idle()),
      child: const _TripHistoryView(),
    );
  }
}

class _TripHistoryView extends StatelessWidget {
  const _TripHistoryView();

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Center(
            child: Material(
              color: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    isAr
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    color: const Color(0xFF101828),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          isAr ? 'سجل الرحلات' : 'Trip History',
          style: AppTextStyles.titleLarge.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF101828),
            letterSpacing: -0.4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: BlocBuilder<PassengerTripsCubit, PassengerTripsState>(
        builder: (context, state) {
          if (state.status == PassengerTripsStatus.loading &&
              state.historyTrips.isEmpty) {
            return const Center(child: AmomyBusLoading.medium());
          }

          if (state.historyTrips.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  context.read<PassengerTripsCubit>().loadTripsHub(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 48,
                ),
                children: [
                  Center(
                    child: Image.asset(
                      AppAssets.tripHistoryEmpty,
                      height: 320,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    isAr ? 'لا يوجد سجل رحلات بعد' : 'No trip history yet',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'ستظهر رحلاتك المكتملة والسابقة هنا.'
                        : 'Your completed trips will appear here.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.read<PassengerTripsCubit>().loadTripsHub(),
                      icon: const Icon(AppIcons.refresh, size: 16),
                      label: Text(isAr ? 'تحديث السجل' : 'Refresh History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<PassengerTripsCubit>().loadTripsHub(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              itemCount: state.historyTrips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return TripHistoryCard(
                  booking: state.historyTrips[index],
                  animationIndex: index,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
