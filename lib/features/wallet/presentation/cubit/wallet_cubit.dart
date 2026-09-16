import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../../topup/domain/entities/topup_entities.dart';
import '../../../topup/domain/usecases/get_my_topup_requests_usecase.dart';
import '../../domain/entities/point_transaction.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import 'wallet_state.dart';

@injectable
class WalletCubit extends Cubit<WalletState> {
  final GetWalletSummaryUseCase? _getWalletSummaryUseCase;
  final GetWalletTransactionsUseCase? _getWalletTransactionsUseCase;
  final WalletRepository? _walletRepository;
  final GetMyTopUpRequestsUseCase? _getMyTopUpRequestsUseCase;

  StreamSubscription<int>? _balanceSubscription;
  StreamSubscription<PointTransaction>? _transactionSubscription;
  StreamSubscription<void>? _topUpUpdatesSubscription;

  WalletCubit(
    this._getWalletSummaryUseCase,
    this._getWalletTransactionsUseCase, [
    this._walletRepository,
    GetMyTopUpRequestsUseCase? getMyTopUpRequestsUseCase,
  ]) : _getMyTopUpRequestsUseCase =
           getMyTopUpRequestsUseCase ??
           (getIt.isRegistered<GetMyTopUpRequestsUseCase>()
               ? getIt<GetMyTopUpRequestsUseCase>()
               : null),
       super(const WalletState());

  WalletCubit.idle()
    : _getWalletSummaryUseCase = null,
      _getWalletTransactionsUseCase = null,
      _walletRepository = null,
      _getMyTopUpRequestsUseCase = null,
      super(const WalletState());

  Future<void> loadWalletSummary(String userId) async {
    if (_getWalletSummaryUseCase == null) return;
    emit(state.copyWith(status: WalletStatus.loading));

    final summaryFuture = _getWalletSummaryUseCase.call(userId);
    final txFuture = _getWalletTransactionsUseCase?.call(userId);
    final topUpFuture = _getMyTopUpRequestsUseCase?.call();

    final summaryResult = await summaryFuture;
    final txResult = txFuture != null ? await txFuture : null;
    final topUpResult = topUpFuture != null ? await topUpFuture : null;

    summaryResult.fold(
      onSuccess: (summary) {
        List<PointTransaction> txs = const [];
        txResult?.fold(onSuccess: (list) => txs = list, onError: (_) {});

        List<TopUpRequest> topUps = const [];
        topUpResult?.fold(onSuccess: (list) => topUps = list, onError: (_) {});

        emit(
          state.copyWith(
            status: WalletStatus.loaded,
            summary: summary,
            transactions: txs,
            topUpRequests: topUps,
          ),
        );

        // Start listening to real-time wallet balance and top-up changes
        _startListeningToBalance(userId);
        _startListeningToTransactions(userId);
        _startListeningToTopUps(userId);
      },
      onError: (failure) => emit(
        state.copyWith(
          status: WalletStatus.error,
          errorMessage: failure.message,
        ),
      ),
    );
  }

  void _startListeningToBalance(String userId) {
    if (_walletRepository == null || userId.isEmpty) return;
    _balanceSubscription?.cancel();
    debugPrint('[REALTIME_DIAG] wallets subscribe start');
    _balanceSubscription = _walletRepository
        .subscribeToWalletBalance(userId)
        .listen(
          (newBalance) {
            debugPrint(
              '[REALTIME_DIAG] wallets subscribe success (event received)',
            );
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
          onError: (error, stackTrace) {
            debugPrint(
              '[REALTIME_DIAG] wallets subscribe error: ${error.runtimeType}',
            );
          },
          cancelOnError: false,
        );
  }

  void _startListeningToTransactions(String userId) {
    if (_walletRepository == null || userId.isEmpty) return;
    _transactionSubscription?.cancel();
    debugPrint('[REALTIME_DIAG] point_transactions subscribe start');
    _transactionSubscription = _walletRepository
        .subscribeToPointTransactions(userId)
        .listen(
          (transaction) {
            debugPrint(
              '[REALTIME_DIAG] point_transactions subscribe success (event received)',
            );
            emit(
              state.copyWith(
                transactions: _mergeTransaction(
                  state.transactions,
                  transaction,
                ),
              ),
            );
          },
          onError: (error, stackTrace) {
            debugPrint(
              '[REALTIME_DIAG] point_transactions subscribe error: ${error.runtimeType}',
            );
          },
          cancelOnError: false,
        );
  }

  List<PointTransaction> _mergeTransaction(
    List<PointTransaction> current,
    PointTransaction incoming,
  ) {
    final byId = <String, PointTransaction>{
      for (final transaction in current) transaction.id: transaction,
    };
    byId[incoming.id] = incoming;

    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  void _startListeningToTopUps(String userId) {
    if (_getMyTopUpRequestsUseCase == null || userId.isEmpty) return;
    _topUpUpdatesSubscription?.cancel();
    debugPrint('[REALTIME_DIAG] topup_requests subscribe start');
    _topUpUpdatesSubscription = _getMyTopUpRequestsUseCase
        .subscribeToUpdates()
        .listen(
          (_) {
            debugPrint(
              '[REALTIME_DIAG] topup_requests subscribe success (event received)',
            );
            _loadTransactionsAndTopUpsSilently(userId, reloadSummary: true);
          },
          onError: (error, stackTrace) {
            debugPrint(
              '[REALTIME_DIAG] topup_requests subscribe error: ${error.runtimeType}',
            );
          },
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

  @override
  Future<void> close() {
    _balanceSubscription?.cancel();
    _transactionSubscription?.cancel();
    _topUpUpdatesSubscription?.cancel();
    return super.close();
  }
}
