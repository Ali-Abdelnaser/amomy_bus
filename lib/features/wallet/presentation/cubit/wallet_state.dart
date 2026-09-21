import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../topup/domain/entities/topup_entities.dart';
import '../../domain/entities/point_transaction.dart';
import '../../domain/entities/wallet_history_event.dart';
import '../../domain/entities/wallet_summary.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final WalletSummary summary;
  final List<PointTransaction> transactions;
  final List<WalletHistoryEvent> historyEvents;
  final bool hasMoreHistory;
  final WalletHistoryCursor? nextCursor;
  final bool isLoadingMoreHistory;
  final List<TopUpRequest> topUpRequests;
  final String? errorMessage;
  final Failure? errorFailure;

  const WalletState({
    this.status = WalletStatus.initial,
    this.summary = const WalletSummary.empty(),
    this.transactions = const [],
    this.historyEvents = const [],
    this.hasMoreHistory = false,
    this.nextCursor,
    this.isLoadingMoreHistory = false,
    this.topUpRequests = const [],
    this.errorMessage,
    this.errorFailure,
  });

  WalletState copyWith({
    WalletStatus? status,
    WalletSummary? summary,
    List<PointTransaction>? transactions,
    List<WalletHistoryEvent>? historyEvents,
    bool? hasMoreHistory,
    WalletHistoryCursor? Function()? nextCursor,
    bool? isLoadingMoreHistory,
    List<TopUpRequest>? topUpRequests,
    String? errorMessage,
    Failure? errorFailure,
    bool clearError = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      historyEvents: historyEvents ?? this.historyEvents,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
      topUpRequests: topUpRequests ?? this.topUpRequests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorFailure: clearError ? null : (errorFailure ?? this.errorFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    transactions,
    historyEvents,
    hasMoreHistory,
    nextCursor,
    isLoadingMoreHistory,
    topUpRequests,
    errorMessage,
    errorFailure,
  ];
}
