import '../../../../core/typedefs/typedefs.dart';
import '../entities/point_transaction.dart';
import '../entities/wallet_summary.dart';

abstract class WalletRepository {
  ResultFuture<WalletSummary> getWalletSummary(String userId);
  ResultFuture<List<PointTransaction>> getTransactions(
    String userId, {
    int limit = 20,
  });
  Stream<int> subscribeToWalletBalance(String userId);
  Stream<PointTransaction> subscribeToPointTransactions(String userId);
}
