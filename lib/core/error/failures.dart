import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.statusCode,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'A server error occurred. Please try again later.',
    super.statusCode,
  });
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Authentication failed or session expired.',
    super.statusCode,
  });
}

class AuthCancelledFailure extends Failure {
  const AuthCancelledFailure({
    super.message = 'Authentication was cancelled.',
    super.statusCode,
  });
}

class ConfigurationFailure extends Failure {
  const ConfigurationFailure({required super.message, super.statusCode});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode});
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache read/write operation failed.',
    super.statusCode,
  });
}

class InvalidAmountFailure extends Failure {
  const InvalidAmountFailure({
    super.message = 'Requested amount must be greater than zero.',
    super.statusCode,
  });
}

class DuplicatePaymentReferenceFailure extends Failure {
  const DuplicatePaymentReferenceFailure({
    super.message =
        'A top-up request with this payment reference is already active or approved.',
    super.statusCode,
  });
}

class ProofUploadFailedFailure extends Failure {
  const ProofUploadFailedFailure({
    super.message = 'Failed to upload payment proof. Please try again.',
    super.statusCode,
  });
}

class RequestNotFoundFailure extends Failure {
  const RequestNotFoundFailure({
    super.message = 'Top-up request was not found.',
    super.statusCode,
  });
}

class RequestAlreadyReviewedFailure extends Failure {
  const RequestAlreadyReviewedFailure({
    super.message = 'This top-up request has already been reviewed.',
    super.statusCode,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.statusCode,
  });
}
