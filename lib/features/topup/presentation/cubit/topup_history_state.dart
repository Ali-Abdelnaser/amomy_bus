import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/topup_entities.dart';

enum TopUpHistoryStatus { initial, loading, success, failure }

class TopUpHistoryState extends Equatable {
  final TopUpHistoryStatus status;
  final List<TopUpRequest> requests;
  final String? errorMessage;
  final Failure? errorFailure;

  const TopUpHistoryState({
    this.status = TopUpHistoryStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.errorFailure,
  });

  bool get isLoading => status == TopUpHistoryStatus.loading;

  TopUpHistoryState copyWith({
    TopUpHistoryStatus? status,
    List<TopUpRequest>? requests,
    String? Function()? errorMessage,
    Failure? Function()? errorFailure,
  }) {
    final nextErrorMessage = errorMessage != null
        ? errorMessage()
        : this.errorMessage;
    final nextErrorFailure = errorFailure != null
        ? errorFailure()
        : (errorMessage != null ? null : this.errorFailure);

    return TopUpHistoryState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: nextErrorMessage,
      errorFailure: nextErrorFailure,
    );
  }

  @override
  List<Object?> get props => [status, requests, errorMessage, errorFailure];
}
