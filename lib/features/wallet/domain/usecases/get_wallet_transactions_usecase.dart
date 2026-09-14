import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/point_transaction.dart';
import '../repositories/wallet_repository.dart';

@lazySingleton
class GetWalletTransactionsUseCase {
  final WalletRepository _repository;

  const GetWalletTransactionsUseCase(this._repository);

  ResultFuture<List<PointTransaction>> call(String userId, {int limit = 20}) {
    return _repository.getTransactions(userId, limit: limit);
  }
}
