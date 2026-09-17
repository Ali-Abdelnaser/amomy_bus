import 'package:amomy_bus/features/wallet/domain/entities/point_transaction.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/wallet_history_event.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl(this._remoteDataSource);

  @override
  ResultFuture<WalletSummary> getWalletSummary(String userId) async {
    try {
      final result = await _remoteDataSource.getWalletSummary(userId);
      return Success(result);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<List<PointTransaction>> getTransactions(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final result = await _remoteDataSource.getTransactions(
        userId,
        limit: limit,
      );
      return Success(result);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<WalletHistoryPage> getWalletHistory({
    int limit = 20,
    String? beforeCreatedAt,
    String? beforeEventId,
  }) async {
    try {
      final result = await _remoteDataSource.getWalletHistory(
        limit: limit,
        beforeCreatedAt: beforeCreatedAt,
        beforeEventId: beforeEventId,
      );
      return Success(result);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  Stream<int> subscribeToWalletBalance(String userId) {
    return _remoteDataSource.subscribeToWalletBalance(userId);
  }

  @override
  Stream<PointTransaction> subscribeToPointTransactions(String userId) {
    return _remoteDataSource.subscribeToPointTransactions(userId);
  }
}
