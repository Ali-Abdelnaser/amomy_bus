import 'package:equatable/equatable.dart';

/// Clean domain entity representing a passenger's wallet summary.
///
/// Exposes strictly consumer-facing point balances.
/// Never exposes point batch IDs, held allocations, or internal accounting fields.
class WalletSummary extends Equatable {
  final int totalAvailablePoints;
  final int cashPoints;
  final int subscriptionPoints;

  const WalletSummary({
    required this.totalAvailablePoints,
    required this.cashPoints,
    required this.subscriptionPoints,
  });

  const WalletSummary.empty()
      : totalAvailablePoints = 0,
        cashPoints = 0,
        subscriptionPoints = 0;

  @override
  List<Object?> get props => [
        totalAvailablePoints,
        cashPoints,
        subscriptionPoints,
      ];
}
