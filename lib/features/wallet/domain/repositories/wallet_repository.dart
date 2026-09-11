import '../../../../core/typedefs/typedefs.dart';
import '../entities/wallet_summary.dart';

abstract class WalletRepository {
  ResultFuture<WalletSummary> getWalletSummary(String userId);
}
