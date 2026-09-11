import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet_summary.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final WalletSummary summary;
  final String? errorMessage;

  const WalletState({
    this.status = WalletStatus.initial,
    this.summary = const WalletSummary.empty(),
    this.errorMessage,
  });

  WalletState copyWith({
    WalletStatus? status,
    WalletSummary? summary,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
