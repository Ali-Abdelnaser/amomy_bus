import 'package:equatable/equatable.dart';
import '../../../topup/domain/entities/topup_entities.dart';
import '../../domain/entities/point_transaction.dart';
import '../../domain/entities/wallet_summary.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final WalletSummary summary;
  final List<PointTransaction> transactions;
  final List<TopUpRequest> topUpRequests;
  final String? errorMessage;

  const WalletState({
    this.status = WalletStatus.initial,
    this.summary = const WalletSummary.empty(),
    this.transactions = const [],
    this.topUpRequests = const [],
    this.errorMessage,
  });

  WalletState copyWith({
    WalletStatus? status,
    WalletSummary? summary,
    List<PointTransaction>? transactions,
    List<TopUpRequest>? topUpRequests,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      topUpRequests: topUpRequests ?? this.topUpRequests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summary, transactions, topUpRequests, errorMessage];
}
