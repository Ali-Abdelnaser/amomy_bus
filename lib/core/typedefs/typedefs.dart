import '../error/failures.dart';

/// Clean Result Monad for Repository and UseCase return types
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Error() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Error(:final failure) => failure,
  };

  R fold<R>({
    required R Function(Failure failure) onError,
    required R Function(T data) onSuccess,
  }) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Error(:final failure) => onError(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

typedef ResultFuture<T> = Future<Result<T>>;
typedef JSON = Map<String, dynamic>;
