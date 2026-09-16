import 'package:flutter/foundation.dart';
import 'package:amomy_bus/features/wallet/data/models/point_transaction_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_summary_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletSummaryModel> getWalletSummary(String userId);
  Future<List<PointTransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
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
  Stream<int> subscribeToWalletBalance(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }

    debugPrint('[REALTIME_DIAG] wallets subscribe start');
    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
          debugPrint('[REALTIME_DIAG] wallets event');
          if (rows.isEmpty) return 0;
          final raw = rows.first['cached_available_balance'];
          if (raw is num) return raw.toInt();
          if (raw is String) return (double.tryParse(raw) ?? 0).toInt();
          return 0;
        })
        .handleError((error, stackTrace) {
          debugPrint('[REALTIME_DIAG] wallets error: ${error.runtimeType}');
        });
  }

  @override
  Stream<PointTransactionModel> subscribeToPointTransactions(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }

    debugPrint('[REALTIME_DIAG] point_transactions subscribe start');
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
        .handleError((error, stackTrace) {
          debugPrint(
            '[REALTIME_DIAG] point_transactions error: ${error.runtimeType}',
          );
        });
  }
}
