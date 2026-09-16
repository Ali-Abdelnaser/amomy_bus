import '../../../../core/typedefs/typedefs.dart';
import '../entities/point_transaction.dart';
import '../entities/wallet_history_event.dart';
import '../entities/wallet_summary.dart';

abstract class WalletRepository {
  ResultFuture<WalletSummary> getWalletSummary(String userId);
  ResultFuture<List<PointTransaction>> getTransactions(
    String userId, {
    int limit = 20,
  });
  ResultFuture<WalletHistoryPage> getWalletHistory({
    int limit = 20,
    String? beforeCreatedAt,
    String? beforeEventId,
  });
  Stream<int> subscribeToWalletBalance(String userId);
  Stream<PointTransaction> subscribeToPointTransactions(String userId);
}
