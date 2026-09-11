import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_summary_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletSummaryModel> getWalletSummary(String userId);
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
}
