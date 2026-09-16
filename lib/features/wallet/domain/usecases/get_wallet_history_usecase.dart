import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/wallet_history_event.dart';
import '../repositories/wallet_repository.dart';

@lazySingleton
class GetWalletHistoryUseCase {
  final WalletRepository _repository;

  const GetWalletHistoryUseCase(this._repository);

  ResultFuture<WalletHistoryPage> call({
    int limit = 20,
    String? beforeCreatedAt,
    String? beforeEventId,
  }) {
    return _repository.getWalletHistory(
      limit: limit,
      beforeCreatedAt: beforeCreatedAt,
      beforeEventId: beforeEventId,
    );
  }
}
