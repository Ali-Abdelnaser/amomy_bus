import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  const ErrorHandler._();

  static Failure handle(dynamic error) {
    if (error is Failure) {
      return error;
    }

    if (error is AppException) {
      return _mapAppException(error);
    }

    if (error is DioException) {
      return _mapDioException(error);
    }

    if (error is AuthException) {
      return AuthenticationFailure(
        message: error.message,
        statusCode: int.tryParse(error.statusCode ?? ''),
      );
    }

    if (error is PostgrestException) {
      return ServerFailure(
        message: error.message,
        statusCode: int.tryParse(error.code ?? ''),
      );
    }

    return UnknownFailure(
      message: error?.toString() ?? 'An unexpected error occurred.',
    );
  }

  static Failure _mapAppException(AppException exception) {
    return switch (exception) {
      NetworkException(:final message, :final statusCode) =>
        NetworkFailure(message: message, statusCode: statusCode),
      ServerException(:final message, :final statusCode) =>
        ServerFailure(message: message, statusCode: statusCode),
      UnauthorizedException(:final message, :final statusCode) =>
        AuthenticationFailure(message: message, statusCode: statusCode),
      ForbiddenException(:final message, :final statusCode) =>
        PermissionFailure(message: message, statusCode: statusCode),
      ValidationException(:final message, :final statusCode) =>
        ValidationFailure(message: message, statusCode: statusCode),
      CacheException(:final message) => CacheFailure(message: message),
      _ => ServerFailure(
          message: exception.message,
          statusCode: exception.statusCode,
        ),
    };
  }

  static Failure _mapDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message: 'Connection timed out or network unreachable.',
        );
      case DioExceptionType.badResponse:
        final status = dioException.response?.statusCode;
        final data = dioException.response?.data;
        String message = 'Server returned an error.';
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (data is String && data.isNotEmpty) {
          message = data;
        }

        if (status == 401) {
          return AuthenticationFailure(message: message, statusCode: status);
        } else if (status == 403) {
          return PermissionFailure(message: message, statusCode: status);
        } else if (status == 422 || status == 400) {
          return ValidationFailure(message: message, statusCode: status);
        } else {
          return ServerFailure(message: message, statusCode: status);
        }
      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Request was cancelled.');
      case DioExceptionType.unknown:
      default:
        return UnknownFailure(
          message: dioException.message ?? 'Unknown network failure occurred.',
        );
    }
  }
}
