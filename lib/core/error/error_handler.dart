import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/app_locale_controller.dart';
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
      final isAr = AppLocaleController.instance.isArabic;
      final msg = error.message.toLowerCase();
      final status = int.tryParse(error.statusCode ?? '');

      if (msg.contains('rate limit') || status == 429) {
        return AuthenticationFailure(
          message: isAr
              ? 'يرجى الانتظار قليلاً قبل طلب رمز جديد.'
              : 'Please wait before requesting another code.',
          statusCode: 429,
        );
      }

      // Supabase GoTrue returns "Token has expired or is invalid" (HTTP 403)
      // for any incorrect, consumed, or invalid OTP code.
      // Differentiate between "invalid" (including "expired or is invalid") and pure "expired".
      if (msg.contains('token has expired or is invalid') ||
          (msg.contains('invalid') &&
              (msg.contains('token') ||
                  msg.contains('otp') ||
                  msg.contains('code')))) {
        return AuthenticationFailure(
          message: isAr
              ? 'رمز التحقق غير صحيح.'
              : 'The verification code is incorrect.',
          statusCode: status,
        );
      }

      if (msg.contains('expired')) {
        return AuthenticationFailure(
          message: isAr
              ? 'انتهت صلاحية هذا الرمز. يرجى طلب رمز جديد.'
              : 'This code has expired. Request a new one.',
          statusCode: status,
        );
      }

      return AuthenticationFailure(message: error.message, statusCode: status);
    }

    if (error is PostgrestException) {
      if (error.code == '23505') {
        final message = AppLocaleController.instance.isArabic
            ? 'البيانات المدخلة (رقم الهاتف أو البريد) مسجلة مسبقاً لحساب آخر.'
            : 'The entered details (phone or email) are already in use by another account.';
        return ValidationFailure(message: message, statusCode: 409);
      }
      return ServerFailure(
        message: error.message,
        statusCode: int.tryParse(error.code ?? ''),
      );
    }

    // GoogleSignInException specific handling
    if (error is GoogleSignInException) {
      final desc = error.description ?? '';
      final isError16 =
          desc.contains('Account reauth failed') ||
          desc.contains('[16]') ||
          desc.contains('16');

      if (isError16) {
        final message = AppLocaleController.instance.isArabic
            ? 'تعذر إكمال تسجيل الدخول باستخدام Google. حاول مرة أخرى.'
            : 'Google sign-in could not be completed. Please try again.';
        return AuthenticationFailure(message: message);
      }

      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const AuthCancelledFailure();
      }

      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          desc.contains('DEVELOPER_ERROR') ||
          desc.contains('10')) {
        final message = AppLocaleController.instance.isArabic
            ? 'خطأ في إعدادات تسجيل الدخول بواسطة Google.'
            : 'Google Sign-In configuration error (DEVELOPER_ERROR/code 10).';
        return ConfigurationFailure(message: message);
      }

      final message = AppLocaleController.instance.isArabic
          ? 'تعذر إكمال تسجيل الدخول باستخدام Google. حاول مرة أخرى.'
          : 'Google sign-in could not be completed. Please try again.';
      return AuthenticationFailure(message: message);
    }

    final errorStr = error?.toString() ?? '';
    final isGoogleError16 =
        errorStr.contains('Account reauth failed') ||
        (errorStr.contains('[16]') && errorStr.contains('GoogleSignIn'));

    if (isGoogleError16) {
      final message = AppLocaleController.instance.isArabic
          ? 'تعذر إكمال تسجيل الدخول باستخدام Google. حاول مرة أخرى.'
          : 'Google sign-in could not be completed. Please try again.';
      return AuthenticationFailure(message: message);
    }

    final isGoogleCancellation =
        errorStr.contains('sign_in_canceled') ||
        errorStr.contains('popup_closed_by_user') ||
        errorStr.contains('User canceled Google Sign-In') ||
        errorStr.contains('The user canceled the sign-in flow');

    if (isGoogleCancellation) {
      return const AuthCancelledFailure();
    }

    if (errorStr.contains('AuthConfigurationException') ||
        errorStr.contains('GOOGLE_WEB_CLIENT_ID') ||
        errorStr.contains('GOOGLE_IOS_CLIENT_ID')) {
      return ConfigurationFailure(
        message: errorStr.replaceFirst('AuthConfigurationException: ', ''),
      );
    }

    if (error is SocketException ||
        errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('NetworkRequestFailed') ||
        errorStr.contains('ClientException')) {
      final message = AppLocaleController.instance.isArabic
          ? 'تعذر التحقق من الرمز. تحقق من اتصالك وحاول مرة أخرى.'
          : 'Couldn\'t verify the code. Check your connection and try again.';
      return NetworkFailure(message: message);
    }

    return UnknownFailure(
      message: error?.toString() ?? 'An unexpected error occurred.',
    );
  }

  static Failure _mapAppException(AppException exception) {
    return switch (exception) {
      NetworkException(:final message, :final statusCode) => NetworkFailure(
        message: message,
        statusCode: statusCode,
      ),
      ServerException(:final message, :final statusCode) => ServerFailure(
        message: message,
        statusCode: statusCode,
      ),
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
