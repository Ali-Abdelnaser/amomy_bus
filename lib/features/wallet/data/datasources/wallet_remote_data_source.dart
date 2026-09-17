import 'package:amomy_bus/features/wallet/data/models/point_transaction_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_history_event_model.dart';
import '../models/wallet_summary_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletSummaryModel> getWalletSummary(String userId);
  Future<List<PointTransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
  });
  Future<WalletHistoryPageModel> getWalletHistory({
    int limit = 20,
    String? beforeCreatedAt,
    String? beforeEventId,
  });
  Stream<int> subscribeToWalletBalance(String userId);
  Stream<PointTransactionModel> subscribeToPointTransactions(String userId);
}

@LazySingleton(as: WalletRemoteDataSource)
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final SupabaseClient _supabase;

  WalletRemoteDataSourceImpl(this._supabase);

  @override
  Future<WalletSummaryModel> getWalletSummary(String userId) async {
    final walletData = await _supabase
        .from('wallets')
        .select('id, user_id, cached_available_balance')
        .eq('user_id', userId)
        .maybeSingle();

    if (walletData == null) {
      return const WalletSummaryModel(
        totalAvailablePoints: 0,
        cashPoints: 0,
        subscriptionPoints: 0,
      );
    }

    List<Map<String, dynamic>> batches = [];
    try {
      final response = await _supabase
          .from('point_batches')
          .select('source_type, remaining_amount')
          .eq('user_id', userId)
          .gt('remaining_amount', 0);
      batches = List<Map<String, dynamic>>.from(response);
    } catch (_) {
      // Safe fallback: if point batches table query fails, cached_available_balance is used.
    }

    return WalletSummaryModel.fromBackend(
      walletData: walletData,
      pointBatches: batches,
    );
  }

  @override
  Future<List<PointTransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
  }) async {
    final response = await _supabase
        .from('point_transactions')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = response as List<dynamic>;
    return list
        .map(
          (item) =>
              PointTransactionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<WalletHistoryPageModel> getWalletHistory({
    int limit = 20,
    String? beforeCreatedAt,
    String? beforeEventId,
  }) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (beforeCreatedAt != null) {
      params['p_before_created_at'] = beforeCreatedAt;
    }
    if (beforeEventId != null) {
      params['p_before_event_id'] = beforeEventId;
    }

    final response = await _supabase.rpc(
      'get_my_wallet_history',
      params: params,
    );

    if (response is Map) {
      return WalletHistoryPageModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    }

    return const WalletHistoryPageModel(events: [], hasMore: false);
  }

  @override
  Stream<int> subscribeToWalletBalance(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }

    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return 0;
          final raw = rows.first['cached_available_balance'];
          if (raw is num) return raw.toInt();
          if (raw is String) return (double.tryParse(raw) ?? 0).toInt();
          return 0;
        })
        .handleError((_) {});
  }

  @override
  Stream<PointTransactionModel> subscribeToPointTransactions(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }

    return _supabase
        .from('point_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) =>
              rows.map((row) => PointTransactionModel.fromJson(row)).toList(),
        )
        .expand((rows) => rows)
        .handleError((_) {});
  }
}
