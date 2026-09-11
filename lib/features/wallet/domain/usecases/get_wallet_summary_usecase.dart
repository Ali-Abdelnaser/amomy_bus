import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/wallet_summary.dart';
import '../repositories/wallet_repository.dart';

@lazySingleton
class GetWalletSummaryUseCase {
  final WalletRepository _repository;

  const GetWalletSummaryUseCase(this._repository);

  ResultFuture<WalletSummary> call(String userId) {
    return _repository.getWalletSummary(userId);
  }
}
