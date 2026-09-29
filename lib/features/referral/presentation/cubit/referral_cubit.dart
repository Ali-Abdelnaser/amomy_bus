import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/referral_repository.dart';
import '../../domain/usecases/referral_usecases.dart';
import 'referral_state.dart';

@injectable
class ReferralCubit extends Cubit<ReferralState> {
  final GetMyReferralDashboardUseCase getDashboardUseCase;
  final PreviewReferralCodeUseCase previewCodeUseCase;
  final BindReferralCodeUseCase bindCodeUseCase;
  final ReferralRepository? repository;

  StreamSubscription<void>? _settingsSubscription;
  StreamSubscription<void>? _dashboardSubscription;
  Timer? _debounceTimer;

  ReferralCubit({
    required this.getDashboardUseCase,
    required this.previewCodeUseCase,
    required this.bindCodeUseCase,
    this.repository,
  }) : super(const ReferralState());

  /// Starts listening to changes on referral_settings.
  /// When settings change, silently/safely reloads dashboard data.
  void startListeningToSettings() {
    if (repository == null || _settingsSubscription != null) return;
    try {
      _settingsSubscription = repository!
          .subscribeToReferralSettingsUpdates()
          .listen(
            (_) => _onRealtimeSignal(),
            onError: (_) {},
            cancelOnError: false,
          );
    } catch (_) {}
  }

  /// Starts listening to changes on all referral tables (settings, referrals, rewards, qualified trips).
  /// Signals trigger reloading get_my_referral_dashboard().
  void startListeningToDashboardUpdates() {
    if (repository == null || _dashboardSubscription != null) return;
    try {
      _dashboardSubscription = repository!
          .subscribeToReferralDashboardUpdates()
          .listen(
            (_) => _onRealtimeSignal(),
            onError: (_) {},
            cancelOnError: false,
          );
    } catch (_) {}
  }

  void _onRealtimeSignal() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      loadDashboard(isRefresh: true);
    });
  }

  Future<void> loadDashboard({bool isRefresh = false}) async {
    if (!isRefresh && state.status == ReferralStatus.loading) return;

    if (!isRefresh || state.dashboard == null) {
      emit(state.copyWith(
        status: ReferralStatus.loading,
        errorMessage: null,
      ));
    }

    final result = await getDashboardUseCase();

    result.fold(
      onError: (failure) {
        // If we already have a dashboard loaded and a background/realtime refresh failed,
        // do not break existing loaded UI
        if (state.dashboard != null) {
          emit(state.copyWith(
            status: ReferralStatus.loaded,
            errorMessage: null,
          ));
        } else {
          emit(state.copyWith(
            status: ReferralStatus.error,
            errorMessage: failure.message,
          ));
        }
      },
      onSuccess: (dashboard) {
        emit(state.copyWith(
          status: ReferralStatus.loaded,
          dashboard: dashboard,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> previewCode(String code, {bool isArabic = true}) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      emit(state.copyWith(
        previewStatus: ReferralPreviewStatus.error,
        previewError: isArabic
            ? 'يرجى إدخال كود الدعوة أولاً'
            : 'Please enter a referral code first',
      ));
      return;
    }

    emit(state.copyWith(
      previewStatus: ReferralPreviewStatus.loading,
      previewError: null,
    ));

    final result = await previewCodeUseCase(cleanCode);

    result.fold(
      onError: (failure) {
        emit(state.copyWith(
          previewStatus: ReferralPreviewStatus.error,
          previewError: failure.message,
        ));
      },
      onSuccess: (preview) {
        if (!preview.valid) {
          emit(state.copyWith(
            previewStatus: ReferralPreviewStatus.error,
            preview: preview,
            previewError: preview.localizedError(isArabic: isArabic),
          ));
        } else {
          emit(state.copyWith(
            previewStatus: ReferralPreviewStatus.success,
            preview: preview,
            previewError: null,
          ));
        }
      },
    );
  }

  void clearPreview() {
    emit(state.copyWith(clearPreview: true));
  }

  Future<bool> bindCode({
    required String code,
    required String source,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    emit(state.copyWith(
      bindStatus: ReferralBindStatus.loading,
      bindError: null,
    ));

    final result = await bindCodeUseCase(
      code: cleanCode,
      source: source,
    );

    return result.fold(
      onError: (failure) {
        emit(state.copyWith(
          bindStatus: ReferralBindStatus.error,
          bindError: failure.message,
        ));
        return false;
      },
      onSuccess: (bindResult) {
        emit(state.copyWith(
          bindStatus: ReferralBindStatus.success,
          bindResult: bindResult,
          bindError: null,
          clearPreview: true,
        ));
        // Refresh dashboard immediately after binding
        loadDashboard(isRefresh: true);
        return true;
      },
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _settingsSubscription?.cancel();
    _dashboardSubscription?.cancel();
    return super.close();
  }
}
