import '../../domain/entities/point_transaction.dart';

class PointTransactionModel extends PointTransaction {
  const PointTransactionModel({
    required super.id,
    required super.userId,
    required super.walletId,
    super.batchId,
    required super.transactionType,
    required super.amount,
    super.balanceBefore,
    super.balanceAfter,
    super.referenceType,
    super.referenceId,
    super.description,
    super.metadata,
    required super.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawType =
        (json['transaction_type'] as String?)?.toLowerCase() ?? 'debit';
    final txType = rawType == 'credit'
        ? PointTransactionType.credit
        : PointTransactionType.debit;

    final rawAmount = json['amount'];
    final int amount = (rawAmount is num) ? rawAmount.toInt() : 0;

    final rawBalanceBefore = json['balance_before'];
    final int? balanceBefore = (rawBalanceBefore is num)
        ? rawBalanceBefore.toInt()
        : null;

    final rawBalanceAfter = json['balance_after'];
    final int? balanceAfter = (rawBalanceAfter is num)
        ? rawBalanceAfter.toInt()
        : null;

    final rawDate = json['created_at'];
    final createdAt = rawDate != null
        ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
        : DateTime.now();

    final rawMeta = json['metadata'];
    final Map<String, dynamic> metadata = rawMeta is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMeta)
        : const {};

    return PointTransactionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      walletId: json['wallet_id'] as String? ?? '',
      batchId: json['batch_id'] as String?,
      transactionType: txType,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      description: json['description'] as String?,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
