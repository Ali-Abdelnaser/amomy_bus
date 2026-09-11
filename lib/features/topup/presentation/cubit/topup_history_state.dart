import 'package:equatable/equatable.dart';
import '../../domain/entities/topup_entities.dart';

enum TopUpHistoryStatus { initial, loading, success, failure }

class TopUpHistoryState extends Equatable {
  final TopUpHistoryStatus status;
  final List<TopUpRequest> requests;
  final String? errorMessage;

  const TopUpHistoryState({
    this.status = TopUpHistoryStatus.initial,
    this.requests = const [],
    this.errorMessage,
  });

  bool get isLoading => status == TopUpHistoryStatus.loading;

  TopUpHistoryState copyWith({
    TopUpHistoryStatus? status,
    List<TopUpRequest>? requests,
    String? Function()? errorMessage,
  }) {
    return TopUpHistoryState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, requests, errorMessage];
}
