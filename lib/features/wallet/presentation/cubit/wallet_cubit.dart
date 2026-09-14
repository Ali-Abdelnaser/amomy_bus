import 'dart:async';
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
  StreamSubscription<void>? _topUpUpdatesSubscription;

  WalletCubit(
    this._getWalletSummaryUseCase,
    this._getWalletTransactionsUseCase, [
    this._walletRepository,
    GetMyTopUpRequestsUseCase? getMyTopUpRequestsUseCase,
  ])  : _getMyTopUpRequestsUseCase = getMyTopUpRequestsUseCase ??
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
        txResult?.fold(
          onSuccess: (list) => txs = list,
          onError: (_) {},
        );

        List<TopUpRequest> topUps = const [];
        topUpResult?.fold(
          onSuccess: (list) => topUps = list,
          onError: (_) {},
        );

        emit(state.copyWith(
          status: WalletStatus.loaded,
          summary: summary,
          transactions: txs,
          topUpRequests: topUps,
        ));

        // Start listening to real-time wallet balance and top-up changes
        _startListeningToBalance(userId);
        _startListeningToTopUps(userId);
      },
      onError: (failure) => emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: failure.message,
      )),
    );
  }

  void _startListeningToBalance(String userId) {
    if (_walletRepository == null || userId.isEmpty) return;
    _balanceSubscription?.cancel();
    _balanceSubscription = _walletRepository.subscribeToWalletBalance(userId).listen((newBalance) {
      if (state.summary.totalAvailablePoints != newBalance) {
        final updatedSummary = WalletSummary(
          totalAvailablePoints: newBalance,
          cashPoints: newBalance,
          subscriptionPoints: 0,
        );
        emit(state.copyWith(summary: updatedSummary));
        _loadTransactionsAndTopUpsSilently(userId);
      }
    });
  }

  void _startListeningToTopUps(String userId) {
    if (_getMyTopUpRequestsUseCase == null) return;
    _topUpUpdatesSubscription?.cancel();
    _topUpUpdatesSubscription = _getMyTopUpRequestsUseCase.subscribeToUpdates().listen((_) {
      _loadTransactionsAndTopUpsSilently(userId, reloadSummary: true);
    });
  }

  Future<void> _loadTransactionsAndTopUpsSilently(String userId, {bool reloadSummary = false}) async {
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
    _topUpUpdatesSubscription?.cancel();
    return super.close();
  }
}
