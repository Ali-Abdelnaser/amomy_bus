import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../../topup/domain/entities/topup_entities.dart';
import '../../../topup/domain/usecases/get_my_topup_requests_usecase.dart';
import '../../domain/entities/point_transaction.dart';
import '../../domain/entities/wallet_history_event.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/get_wallet_history_usecase.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import 'wallet_state.dart';

@injectable
class WalletCubit extends Cubit<WalletState> {
  final GetWalletSummaryUseCase? _getWalletSummaryUseCase;
  final GetWalletTransactionsUseCase? _getWalletTransactionsUseCase;
  final WalletRepository? _walletRepository;
  final GetMyTopUpRequestsUseCase? _getMyTopUpRequestsUseCase;
  final GetWalletHistoryUseCase? _getWalletHistoryUseCase;

  StreamSubscription<int>? _balanceSubscription;
  StreamSubscription<PointTransaction>? _transactionSubscription;
  StreamSubscription<void>? _topUpUpdatesSubscription;
  Timer? _invalidationDebounceTimer;

  WalletCubit(
    this._getWalletSummaryUseCase,
    this._getWalletTransactionsUseCase, [
    this._walletRepository,
    GetMyTopUpRequestsUseCase? getMyTopUpRequestsUseCase,
    GetWalletHistoryUseCase? getWalletHistoryUseCase,
  ]) : _getMyTopUpRequestsUseCase =
           getMyTopUpRequestsUseCase ??
           (getIt.isRegistered<GetMyTopUpRequestsUseCase>()
               ? getIt<GetMyTopUpRequestsUseCase>()
               : null),
       _getWalletHistoryUseCase =
           getWalletHistoryUseCase ??
           (getIt.isRegistered<GetWalletHistoryUseCase>()
               ? getIt<GetWalletHistoryUseCase>()
               : null),
       super(const WalletState());

  WalletCubit.idle()
    : _getWalletSummaryUseCase = null,
      _getWalletTransactionsUseCase = null,
      _walletRepository = null,
      _getMyTopUpRequestsUseCase = null,
      _getWalletHistoryUseCase = null,
      super(const WalletState());

  Future<void> loadWalletSummary(String userId) async {
    if (_getWalletSummaryUseCase == null) return;
    emit(state.copyWith(status: WalletStatus.loading, clearError: true));

    final summaryFuture = _getWalletSummaryUseCase.call(userId);
    final historyFuture = _getWalletHistoryUseCase?.call(limit: 20);
    final txFuture = _getWalletTransactionsUseCase?.call(userId);
    final topUpFuture = _getMyTopUpRequestsUseCase?.call();

    final summaryResult = await summaryFuture;
    final historyResult = historyFuture != null ? await historyFuture : null;
    final txResult = txFuture != null ? await txFuture : null;
    final topUpResult = topUpFuture != null ? await topUpFuture : null;

    summaryResult.fold(
      onSuccess: (summary) {
        List<PointTransaction> txs = const [];
        txResult?.fold(onSuccess: (list) => txs = list, onError: (_) {});

        List<WalletHistoryEvent> historyEvents = const [];
        bool hasMore = false;
        WalletHistoryCursor? cursor;

        historyResult?.fold(
          onSuccess: (page) {
            historyEvents = page.events;
            hasMore = page.hasMore;
            cursor = page.nextCursor;
          },
          onError: (_) {},
        );

        List<TopUpRequest> topUps = const [];
        topUpResult?.fold(onSuccess: (list) => topUps = list, onError: (_) {});

        emit(
          state.copyWith(
            status: WalletStatus.loaded,
            summary: summary,
            transactions: txs,
            historyEvents: historyEvents,
            hasMoreHistory: hasMore,
            nextCursor: () => cursor,
            topUpRequests: topUps,
          ),
        );

        // Start listening to real-time wallet balance, invalidation, and top-up changes
        _startListeningToBalance(userId);
        _startListeningToTransactions(userId);
        _startListeningToTopUps(userId);
      },
      onError: (failure) => emit(
        state.copyWith(status: WalletStatus.error, errorFailure: failure),
      ),
    );
  }

  void _startListeningToBalance(String userId) {
    if (_walletRepository == null || userId.isEmpty) return;
    _balanceSubscription?.cancel();
    _balanceSubscription = _walletRepository
        .subscribeToWalletBalance(userId)
        .listen(
          (newBalance) {
            if (state.summary.totalAvailablePoints != newBalance) {
              final updatedSummary = WalletSummary(
                totalAvailablePoints: newBalance,
                cashPoints: newBalance,
                subscriptionPoints: 0,
              );
              emit(state.copyWith(summary: updatedSummary));
              _loadTransactionsAndTopUpsSilently(userId);
            }
          },
          onError: (_) {},
          cancelOnError: false,
        );
  }

  void _startListeningToTransactions(String userId) {
    if (_walletRepository == null || userId.isEmpty) return;
    _transactionSubscription?.cancel();
    _transactionSubscription = _walletRepository
        .subscribeToPointTransactions(userId)
        .listen(
          (_) {
            // Treat realtime point_transaction as an invalidation signal only.
            // Coalesce rapid invalidations and silently refetch get_my_wallet_history().
            _triggerSemanticHistoryInvalidation(userId);
          },
          onError: (_) {},
          cancelOnError: false,
        );
  }

  void _triggerSemanticHistoryInvalidation(String userId) {
    _invalidationDebounceTimer?.cancel();
    _invalidationDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      _loadTransactionsAndTopUpsSilently(userId, reloadSummary: true);
    });
  }

  void _startListeningToTopUps(String userId) {
    if (_getMyTopUpRequestsUseCase == null || userId.isEmpty) return;
    _topUpUpdatesSubscription?.cancel();
    _topUpUpdatesSubscription = _getMyTopUpRequestsUseCase
        .subscribeToUpdates()
        .listen(
          (_) {
            _loadTransactionsAndTopUpsSilently(userId, reloadSummary: true);
          },
          onError: (_) {},
          cancelOnError: false,
        );
  }

  Future<void> _loadTransactionsAndTopUpsSilently(
    String userId, {
    bool reloadSummary = false,
  }) async {
    if (userId.isEmpty) return;

    if (reloadSummary && _getWalletSummaryUseCase != null) {
      final summaryRes = await _getWalletSummaryUseCase(userId);
      summaryRes.fold(
        onSuccess: (summary) => emit(state.copyWith(summary: summary)),
        onError: (_) {},
      );
    }

    if (_getWalletHistoryUseCase != null) {
      final historyRes = await _getWalletHistoryUseCase(limit: 20);
      historyRes.fold(
        onSuccess: (page) {
          final merged = _mergeHistoryEvents(state.historyEvents, page.events);
          emit(
            state.copyWith(
              historyEvents: merged,
              // If we already had older pages loaded, preserve hasMoreHistory & nextCursor
              // unless we had no older pages.
              hasMoreHistory: state.nextCursor != null
                  ? state.hasMoreHistory
                  : page.hasMore,
              nextCursor: () => state.nextCursor ?? page.nextCursor,
            ),
          );
        },
        onError: (_) {},
      );
    }

    if (_getWalletTransactionsUseCase != null) {
      final txRes = await _getWalletTransactionsUseCase(userId);
      txRes.fold(
        onSuccess: (list) => emit(state.copyWith(transactions: list)),
        onError: (_) {},
      );
    }

    if (_getMyTopUpRequestsUseCase != null) {
      final topUpRes = await _getMyTopUpRequestsUseCase();
      topUpRes.fold(
        onSuccess: (list) => emit(state.copyWith(topUpRequests: list)),
        onError: (_) {},
      );
    }
  }

  /// Merges incoming newest events with existing loaded events by unique event_id,
  /// preserving valid older loaded events and sorting strictly newest-first.
  List<WalletHistoryEvent> _mergeHistoryEvents(
    List<WalletHistoryEvent> existing,
    List<WalletHistoryEvent> incoming,
  ) {
    final byId = <String, WalletHistoryEvent>{};
    for (final event in existing) {
      byId[event.eventId] = event;
    }
    for (final event in incoming) {
      byId[event.eventId] = event;
    }

    final list = byId.values.toList()
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    return list;
  }

  /// Loads older semantic transactions using cursor-based pagination.
  Future<void> loadMoreHistory() async {
    if (_getWalletHistoryUseCase == null) return;
    if (state.isLoadingMoreHistory || !state.hasMoreHistory) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;

    emit(state.copyWith(isLoadingMoreHistory: true));

    final result = await _getWalletHistoryUseCase(
      limit: 20,
      beforeCreatedAt: cursor.createdAt,
      beforeEventId: cursor.eventId,
    );

    result.fold(
      onSuccess: (page) {
        final merged = _mergeHistoryEvents(state.historyEvents, page.events);
        emit(
          state.copyWith(
            isLoadingMoreHistory: false,
            historyEvents: merged,
            hasMoreHistory: page.hasMore,
            nextCursor: () => page.nextCursor,
          ),
        );
      },
      onError: (_) {
        emit(state.copyWith(isLoadingMoreHistory: false));
      },
    );
  }

  @override
  Future<void> close() {
    _invalidationDebounceTimer?.cancel();
    _balanceSubscription?.cancel();
    _transactionSubscription?.cancel();
    _topUpUpdatesSubscription?.cancel();
    return super.close();
  }
}
