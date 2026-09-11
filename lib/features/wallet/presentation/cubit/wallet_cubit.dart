import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_wallet_summary_usecase.dart';
import 'wallet_state.dart';

@injectable
class WalletCubit extends Cubit<WalletState> {
  final GetWalletSummaryUseCase? _getWalletSummaryUseCase;

  WalletCubit(this._getWalletSummaryUseCase) : super(const WalletState());

  WalletCubit.idle()
      : _getWalletSummaryUseCase = null,
        super(const WalletState());

  Future<void> loadWalletSummary(String userId) async {
    if (_getWalletSummaryUseCase == null) return;
    emit(state.copyWith(status: WalletStatus.loading));
    final result = await _getWalletSummaryUseCase(userId);
    result.fold(
      onSuccess: (summary) => emit(state.copyWith(
        status: WalletStatus.loaded,
        summary: summary,
      )),
      onError: (failure) => emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: failure.message,
      )),
    );
  }
}
