import '../../domain/entities/wallet_summary.dart';

class WalletSummaryModel extends WalletSummary {
  const WalletSummaryModel({
    required super.totalAvailablePoints,
    required super.cashPoints,
    required super.subscriptionPoints,
  });

  /// Derives consumer points summary from backend wallet data and point batches.
  ///
  /// If point batches exist, separates cash vs subscription points.
  /// If no batches exist, treats cached available balance as cash points (subscription = 0).
  /// Zero point balance is completely valid.
  factory WalletSummaryModel.fromBackend({
    required Map<String, dynamic>? walletData,
    required List<Map<String, dynamic>> pointBatches,
  }) {
    if (walletData == null) {
      return const WalletSummaryModel(
        totalAvailablePoints: 0,
        cashPoints: 0,
        subscriptionPoints: 0,
      );
    }

    final total =
        (walletData['cached_available_balance'] as num?)?.toInt() ?? 0;
    int cash = 0;
    int subscription = 0;

    if (pointBatches.isNotEmpty) {
      for (final batch in pointBatches) {
        final sourceType = batch['source_type'] as String?;
        final amount = (batch['remaining_amount'] as num?)?.toInt() ?? 0;
        if (sourceType == 'subscription') {
          subscription += amount;
        } else {
          cash += amount;
        }
      }
    } else {
      cash = total;
      subscription = 0;
    }

    return WalletSummaryModel(
      totalAvailablePoints: total,
      cashPoints: cash,
      subscriptionPoints: subscription,
    );
  }
}
