import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/topup_entities.dart';
import '../../domain/usecases/get_my_topup_requests_usecase.dart';
import 'topup_history_state.dart';

@injectable
class TopUpHistoryCubit extends Cubit<TopUpHistoryState> {
  final GetMyTopUpRequestsUseCase? _getMyTopUpRequestsUseCase;
  StreamSubscription<void>? _updatesSubscription;
  void Function()? onApprovedTopUpDetected;

  TopUpHistoryCubit(GetMyTopUpRequestsUseCase getMyTopUpRequestsUseCase)
    : _getMyTopUpRequestsUseCase = getMyTopUpRequestsUseCase,
      super(const TopUpHistoryState());

  TopUpHistoryCubit.idle()
    : _getMyTopUpRequestsUseCase = null,
      super(const TopUpHistoryState(status: TopUpHistoryStatus.success));

  Future<void> loadRequests() async {
    if (_getMyTopUpRequestsUseCase == null) {
      emit(state.copyWith(status: TopUpHistoryStatus.success, requests: []));
      return;
    }

    emit(
      state.copyWith(
        status: TopUpHistoryStatus.loading,
        errorMessage: () => null,
      ),
    );

    final result = await _getMyTopUpRequestsUseCase();
    result.fold(
      onError: (failure) {
        emit(
          state.copyWith(
            status: TopUpHistoryStatus.failure,
            errorMessage: () => failure.message,
          ),
        );
      },
      onSuccess: (requests) {
        // Detect if any previously pending request is now approved
        final hadPending = state.requests.any(
          (r) => r.status == TopUpStatus.pending,
        );
        final nowApproved = requests.any(
          (r) => r.status == TopUpStatus.approved,
        );
        if (hadPending && nowApproved && onApprovedTopUpDetected != null) {
          onApprovedTopUpDetected!();
        }

        emit(
          state.copyWith(
            status: TopUpHistoryStatus.success,
            requests: requests,
          ),
        );
      },
    );
  }

  void startListeningToUpdates() {
    if (_getMyTopUpRequestsUseCase == null) return;
    _updatesSubscription?.cancel();
    _updatesSubscription = _getMyTopUpRequestsUseCase.subscribeToUpdates().listen(
      (_) {
        loadRequests();
      },
      onError: (error, stackTrace) {
        // Realtime subscription failures (e.g. RealtimeSubscribeException / channelError)
        // must not escape to the global bootstrap zone.
        // TopUpHistoryCubit remains usable; last loaded list is preserved.
        debugPrint(
          '[REALTIME_DIAG] topup_requests (history) error: ${error.runtimeType}',
        );
      },
      cancelOnError: false,
    );
  }

  @override
  Future<void> close() {
    _updatesSubscription?.cancel();
    return super.close();
  }
}
