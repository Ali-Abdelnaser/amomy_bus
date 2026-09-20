class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() =>
      'AppException(message: $message, statusCode: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection error.',
    super.statusCode,
    super.originalError,
  });
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error occurred.',
    super.statusCode,
    super.originalError,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized request.',
    super.statusCode = 401,
    super.originalError,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access forbidden.',
    super.statusCode = 403,
    super.originalError,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found.',
    super.statusCode = 404,
    super.originalError,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 422,
    super.originalError,
  });
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred.',
    super.originalError,
  });
}
