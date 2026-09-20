import 'package:equatable/equatable.dart';

enum PointTransactionType { credit, debit }

/// Clean domain entity representing an individual point transaction in the passenger ledger.
class PointTransaction extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final String? batchId;
  final PointTransactionType transactionType;
  final int amount;
  final int? balanceBefore;
  final int? balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const PointTransaction({
    required this.id,
    required this.userId,
    required this.walletId,
    this.batchId,
    required this.transactionType,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.description,
    this.metadata = const {},
    required this.createdAt,
  });

  bool get isCredit => transactionType == PointTransactionType.credit;
  bool get isDebit => transactionType == PointTransactionType.debit;

  @override
  List<Object?> get props => [
    id,
    userId,
    walletId,
    batchId,
    transactionType,
    amount,
    balanceBefore,
    balanceAfter,
    referenceType,
    referenceId,
    description,
    metadata,
    createdAt,
  ];
}
