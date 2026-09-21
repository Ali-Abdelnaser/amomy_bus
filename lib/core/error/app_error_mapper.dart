import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../localization/app_locale_controller.dart';
import 'failures.dart';

/// Centralized error mapping pipeline for Amomy Bus.
/// Transforms raw exceptions, backend codes, and technical errors into localized, user-safe messages.
class AppErrorMapper {
  const AppErrorMapper._();

  /// Maps any dynamic error or exception to a localized user-friendly message using BuildContext.
  static String map(BuildContext context, dynamic error) {
    _logTechnicalError(error);

    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    return _resolveMessage(error, l10n: l10n, isAr: isAr);
  }

  /// Maps any dynamic error or exception without BuildContext using global locale.
  static String mapToString(dynamic error, {bool? isArabic}) {
    _logTechnicalError(error);

    final isAr = isArabic ?? AppLocaleController.instance.isArabic;
    return _resolveMessage(error, l10n: null, isAr: isAr);
  }

  /// Internal resolution logic.
  static String _resolveMessage(
    dynamic error, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    if (error == null) {
      return l10n?.errorGeneric ??
          (isAr
              ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
              : 'Something went wrong. Please try again.');
    }

    // 1. AuthException from Supabase
    if (error is AuthException) {
      return _mapAuthException(error, l10n: l10n, isAr: isAr);
    }

    // 2. DioException
    if (error is DioException) {
      return _mapDioException(error, l10n: l10n, isAr: isAr);
    }

    // 3. PostgrestException from Supabase
    if (error is PostgrestException) {
      return _mapPostgrestException(error, l10n: l10n, isAr: isAr);
    }

    // 4. Low-level Dart IO network errors
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return _mapNetworkError(error, l10n: l10n, isAr: isAr);
    }

    // 5. App Failures
    if (error is Failure) {
      return _mapFailure(error, l10n: l10n, isAr: isAr);
    }

    // 6. String or general exception
    final errorString = error.toString();
    return _mapStringOrCode(errorString, l10n: l10n, isAr: isAr);
  }

  static String _mapAuthException(
    AuthException authEx, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    final msg = authEx.message.toLowerCase();
    final code = (authEx.code ?? '').toLowerCase();
    final status = int.tryParse(authEx.statusCode ?? '');

    // Invalid Login credentials
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        code.contains('invalid_credentials') ||
        msg.contains('invalid username or password') ||
        (status == 400 && msg.contains('invalid') && msg.contains('grant'))) {
      return l10n?.errorInvalidLogin ??
          (isAr
              ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
              : 'Incorrect email or password.');
    }

    // Email not confirmed
    if (msg.contains('email not confirmed') ||
        code.contains('email_not_confirmed') ||
        msg.contains('not confirmed')) {
      return l10n?.errorEmailNotConfirmed ??
          (isAr
              ? 'يرجى تأكيد بريدك الإلكتروني أولًا.'
              : 'Please confirm your email first.');
    }

    // User already registered / exists
    if (msg.contains('user already registered') ||
        msg.contains('user_already_exists') ||
        code.contains('user_already_exists') ||
        msg.contains('already exists')) {
      return l10n?.errorUserAlreadyExists ??
          (isAr
              ? 'يوجد حساب مسجل بهذا البريد الإلكتروني بالفعل.'
              : 'An account with this email already exists.');
    }

    // Invalid email
    if (msg.contains('invalid email') ||
        code.contains('invalid_email') ||
        msg.contains('email address is invalid')) {
      return l10n?.errorInvalidEmail ??
          (isAr
              ? 'يرجى إدخال بريد إلكتروني صحيح.'
              : 'Please enter a valid email address.');
    }

    // Weak password
    if (msg.contains('password') &&
        (msg.contains('weak') ||
            msg.contains('least') ||
            msg.contains('short') ||
            code.contains('weak_password'))) {
      return l10n?.errorWeakPassword ??
          (isAr
              ? 'كلمة المرور ضعيفة. استخدم كلمة مرور أقوى.'
              : 'Your password is too weak. Please choose a stronger password.');
    }

    // Session expired / JWT expired
    if (msg.contains('jwt expired') ||
        msg.contains('session expired') ||
        code.contains('session_expired') ||
        code.contains('session_not_found') ||
        code.contains('refresh_token_not_found') ||
        msg.contains('session not found') ||
        msg.contains('refresh token not found') ||
        msg.contains('token expired') ||
        msg.contains('invalid token')) {
      return l10n?.errorSessionExpired ??
          (isAr
              ? 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.'
              : 'Your session has expired. Please sign in again.');
    }

    // Not authenticated
    if (msg.contains('not authenticated') ||
        code.contains('not_authenticated') ||
        status == 401) {
      return l10n?.errorNotAuthenticated ??
          (isAr
              ? 'يرجى تسجيل الدخول للمتابعة.'
              : 'Please sign in to continue.');
    }

    // Rate limited / Too many requests
    if (msg.contains('rate limit') ||
        code.contains('over_email_send_rate_limit') ||
        code.contains('over_request_rate_limit') ||
        msg.contains('too many requests') ||
        status == 429) {
      return l10n?.errorRateLimited ??
          (isAr
              ? 'عدد المحاولات كبير. حاول مرة أخرى بعد قليل.'
              : 'Too many attempts. Please try again shortly.');
    }

    // OTP verification
    if (msg.contains('expired') &&
        (msg.contains('otp') ||
            msg.contains('token') ||
            msg.contains('code')) ||
        code.contains('otp_expired')) {
      return l10n?.errorOtpExpired ??
          (isAr
              ? 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.'
              : 'The verification code has expired. Request a new one.');
    }

    if (msg.contains('token has expired or is invalid') ||
        code.contains('otp_invalid') ||
        (msg.contains('invalid') &&
            (msg.contains('otp') ||
                msg.contains('token') ||
                msg.contains('code')))) {
      return l10n?.errorOtpInvalid ??
          (isAr
              ? 'رمز التحقق غير صحيح.'
              : 'The verification code is incorrect.');
    }

    // Password reset
    if (msg.contains('password reset') || msg.contains('recovery')) {
      return l10n?.errorPasswordReset ??
          (isAr
              ? 'تعذر إرسال رابط إعادة تعيين كلمة المرور. حاول مرة أخرى.'
              : 'We couldn\'t send the password reset link. Please try again.');
    }

    return l10n?.errorAuthUnknown ??
        (isAr
            ? 'حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى.'
            : 'Something went wrong while signing in. Please try again.');
  }

  static String _mapDioException(
    DioException dioEx, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    switch (dioEx.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n?.errorTimeout ??
            (isAr
                ? 'استغرق الاتصال وقتًا أطول من المتوقع. حاول مرة أخرى.'
                : 'The connection took too long. Please try again.');
      case DioExceptionType.connectionError:
        return l10n?.errorServerUnreachable ??
            (isAr
                ? 'تعذر الاتصال بالخادم حاليًا. حاول مرة أخرى بعد قليل.'
                : 'We couldn\'t connect to the server right now. Please try again shortly.');
      case DioExceptionType.cancel:
        return isAr ? 'تم إلغاء الطلب.' : 'Request was cancelled.';
      case DioExceptionType.badResponse:
        final status = dioEx.response?.statusCode;
        if (status == 401) {
          return l10n?.errorNotAuthenticated ??
              (isAr
                  ? 'يرجى تسجيل الدخول للمتابعة.'
                  : 'Please sign in to continue.');
        } else if (status == 429) {
          return l10n?.errorRateLimited ??
              (isAr
                  ? 'عدد المحاولات كبير. حاول مرة أخرى بعد قليل.'
                  : 'Too many attempts. Please try again shortly.');
        } else if (status != null && status >= 500) {
          return l10n?.errorServerUnreachable ??
              (isAr
                  ? 'تعذر الاتصال بالخادم حاليًا. حاول مرة أخرى بعد قليل.'
                  : 'We couldn\'t connect to the server right now. Please try again shortly.');
        }
        final data = dioEx.response?.data;
        if (data is Map && data['code'] != null) {
          return _mapBackendCode(data['code'].toString(), l10n: l10n, isAr: isAr) ??
              (l10n?.errorGeneric ??
                  (isAr
                      ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
                      : 'Something went wrong. Please try again.'));
        }
        return l10n?.errorGeneric ??
            (isAr
                ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
                : 'Something went wrong. Please try again.');
      case DioExceptionType.unknown:
      default:
        return _mapNetworkError(dioEx.error, l10n: l10n, isAr: isAr);
    }
  }

  static String _mapPostgrestException(
    PostgrestException postgrestEx, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    if (postgrestEx.code == '23505') {
      return l10n?.errorUserAlreadyExists ??
          (isAr
              ? 'يوجد حساب مسجل بهذا البريد الإلكتروني بالفعل.'
              : 'An account with this email already exists.');
    }

    final code = postgrestEx.code ?? '';
    final msg = postgrestEx.message;

    // Check code first, then message
    final mapped = _mapBackendCode(code, l10n: l10n, isAr: isAr);
    if (mapped != null) return mapped;

    return _mapStringOrCode(msg, l10n: l10n, isAr: isAr);
  }

  static String _mapNetworkError(
    dynamic error, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    final errStr = error?.toString().toLowerCase() ?? '';

    if (errStr.contains('socketexception') ||
        errStr.contains('clientexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('host lookup') ||
        errStr.contains('dns') ||
        errStr.contains('connection failed') ||
        errStr.contains('network request failed') ||
        errStr.contains('network unreachable') ||
        errStr.contains('no address associated with hostname') ||
        errStr.contains('network_error') ||
        errStr.contains('network is unreachable')) {
      return l10n?.errorNoInternet ??
          (isAr
              ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.'
              : 'No internet connection. Check your network and try again.');
    }

    if (errStr.contains('timeoutexception') ||
        errStr.contains('timed out') ||
        errStr.contains('deadline exceeded')) {
      return l10n?.errorTimeout ??
          (isAr
              ? 'استغرق الاتصال وقتًا أطول من المتوقع. حاول مرة أخرى.'
              : 'The connection took too long. Please try again.');
    }

    if (errStr.contains('connection refused') ||
        errStr.contains('connection reset') ||
        errStr.contains('server unreachable') ||
        errStr.contains('502') ||
        errStr.contains('503') ||
        errStr.contains('504')) {
      return l10n?.errorServerUnreachable ??
          (isAr
              ? 'تعذر الاتصال بالخادم حاليًا. حاول مرة أخرى بعد قليل.'
              : 'We couldn\'t connect to the server right now. Please try again shortly.');
    }

    return l10n?.errorNetworkProblem ??
        (isAr
            ? 'حدثت مشكلة في الاتصال. حاول مرة أخرى.'
            : 'A network problem occurred. Please try again.');
  }

  static String _mapFailure(
    Failure failure, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    if (failure is NetworkFailure) {
      return _mapNetworkError(failure.message, l10n: l10n, isAr: isAr);
    }
    if (failure is AuthCancelledFailure) {
      return l10n?.errorGoogleSignInCancelled ??
          (isAr
              ? 'تم إلغاء تسجيل الدخول باستخدام Google.'
              : 'Google sign-in was cancelled.');
    }
    if (failure is AuthenticationFailure) {
      return _mapStringOrCode(failure.message, l10n: l10n, isAr: isAr);
    }

    return _mapStringOrCode(failure.message, l10n: l10n, isAr: isAr);
  }

  static String _mapStringOrCode(
    String raw, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    if (raw.trim().isEmpty) {
      return l10n?.errorGeneric ??
          (isAr
              ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
              : 'Something went wrong. Please try again.');
    }

    final lower = raw.toLowerCase();
    final upper = raw.toUpperCase();

    // Check for network patterns in strings
    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('host lookup') ||
        lower.contains('dns') ||
        lower.contains('connection failed') ||
        lower.contains('network request failed') ||
        lower.contains('network unreachable') ||
        lower.contains('no internet')) {
      return l10n?.errorNoInternet ??
          (isAr
              ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.'
              : 'No internet connection. Check your network and try again.');
    }

    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return l10n?.errorTimeout ??
          (isAr
              ? 'استغرق الاتصال وقتًا أطول من المتوقع. حاول مرة أخرى.'
              : 'The connection took too long. Please try again.');
    }

    if (lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('server unreachable')) {
      return l10n?.errorServerUnreachable ??
          (isAr
              ? 'تعذر الاتصال بالخادم حاليًا. حاول مرة أخرى بعد قليل.'
              : 'We couldn\'t connect to the server right now. Please try again shortly.');
    }

    // Check Google Auth patterns
    if (lower.contains('sign_in_canceled') ||
        lower.contains('popup_closed_by_user') ||
        lower.contains('user canceled google sign-in')) {
      return l10n?.errorGoogleSignInCancelled ??
          (isAr
              ? 'تم إلغاء تسجيل الدخول باستخدام Google.'
              : 'Google sign-in was cancelled.');
    }

    if (lower.contains('googlesignin') ||
        lower.contains('account reauth failed') ||
        lower.contains('developer_error')) {
      return l10n?.errorGoogleSignInFailed ??
          (isAr
              ? 'تعذر تسجيل الدخول باستخدام Google. حاول مرة أخرى.'
              : 'We couldn\'t sign you in with Google. Please try again.');
    }

    // Backend business error codes
    final backendResult = _mapBackendCode(upper, l10n: l10n, isAr: isAr);
    if (backendResult != null) return backendResult;

    // Supabase Auth patterns in strings
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return l10n?.errorInvalidLogin ??
          (isAr
              ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
              : 'Incorrect email or password.');
    }

    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return l10n?.errorEmailNotConfirmed ??
          (isAr
              ? 'يرجى تأكيد بريدك الإلكتروني أولًا.'
              : 'Please confirm your email first.');
    }

    if (lower.contains('user already registered') ||
        lower.contains('user_already_exists') ||
        lower.contains('already registered')) {
      return l10n?.errorUserAlreadyExists ??
          (isAr
              ? 'يوجد حساب مسجل بهذا البريد الإلكتروني بالفعل.'
              : 'An account with this email already exists.');
    }

    if (lower.contains('invalid email') || lower.contains('invalid_email')) {
      return l10n?.errorInvalidEmail ??
          (isAr
              ? 'يرجى إدخال بريد إلكتروني صحيح.'
              : 'Please enter a valid email address.');
    }

    if (lower.contains('weak_password') ||
        (lower.contains('password') &&
            (lower.contains('weak') ||
                lower.contains('least') ||
                lower.contains('short')))) {
      return l10n?.errorWeakPassword ??
          (isAr
              ? 'كلمة المرور ضعيفة. استخدم كلمة مرور أقوى.'
              : 'Your password is too weak. Please choose a stronger password.');
    }

    if (lower.contains('over_request_rate_limit') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('too many requests') ||
        lower.contains('rate limit')) {
      return l10n?.errorRateLimited ??
          (isAr
              ? 'عدد المحاولات كبير. حاول مرة أخرى بعد قليل.'
              : 'Too many attempts. Please try again shortly.');
    }

    if (lower.contains('otp_expired')) {
      return l10n?.errorOtpExpired ??
          (isAr
              ? 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.'
              : 'The verification code has expired. Request a new one.');
    }

    if (lower.contains('otp_invalid')) {
      return l10n?.errorOtpInvalid ??
          (isAr
              ? 'رمز التحقق غير صحيح.'
              : 'The verification code is incorrect.');
    }

    if (lower.contains('password reset') || lower.contains('recovery')) {
      return l10n?.errorPasswordReset ??
          (isAr
              ? 'تعذر إرسال رابط إعادة تعيين كلمة المرور. حاول مرة أخرى.'
              : 'We couldn\'t send the password reset link. Please try again.');
    }

    if (lower.contains('jwt expired') ||
        lower.contains('session expired') ||
        lower.contains('session_not_found') ||
        lower.contains('refresh_token_not_found') ||
        lower.contains('token expired')) {
      return l10n?.errorSessionExpired ??
          (isAr
              ? 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.'
              : 'Your session has expired. Please sign in again.');
    }

    if (lower.contains('not authenticated') ||
        lower.contains('auth_required')) {
      return l10n?.errorNotAuthenticated ??
          (isAr
              ? 'يرجى تسجيل الدخول للمتابعة.'
              : 'Please sign in to continue.');
    }

    // Check if the string is raw technical exception
    if (raw.contains('Exception:') ||
        raw.contains('Error:') ||
        raw.contains('PostgrestException') ||
        raw.contains('AuthException') ||
        raw.contains('SqlException') ||
        raw.contains('DatabaseException') ||
        raw.contains('Unhandled') ||
        raw.contains('StackTrace') ||
        raw.contains('null')) {
      return l10n?.errorGeneric ??
          (isAr
              ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
              : 'Something went wrong. Please try again.');
    }

    if (RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(raw.trim())) {
      return l10n?.errorGeneric ??
          (isAr
              ? 'حدث خطأ غير متوقع. حاول مرة أخرى.'
              : 'Something went wrong. Please try again.');
    }

    // If already clean and user-friendly, return as is
    return raw;
  }

  static String? _mapBackendCode(
    String code, {
    required AppLocalizations? l10n,
    required bool isAr,
  }) {
    if (code.contains('NOT_AUTHENTICATED') || code.contains('AUTH_REQUIRED')) {
      return l10n?.errorNotAuthenticated ??
          (isAr
              ? 'يرجى تسجيل الدخول للمتابعة.'
              : 'Please sign in to continue.');
    }
    if (code.contains('TRACKING_ACCESS_DENIED')) {
      return l10n?.errorTrackingAccessDenied ??
          (isAr
              ? 'غير مصرح لك بعرض هذا التتبع.'
              : 'You are not authorized to view this tracking information.');
    }
    if (code.contains('WALLET_NOT_FOUND')) {
      return l10n?.errorWalletNotFound ??
          (isAr
              ? 'لم يتم العثور على المحفظة الخاصة بك.'
              : 'Wallet could not be found.');
    }
    if (code.contains('SEAT_ALREADY_BOOKED') ||
        code.contains('SEAT_UNAVAILABLE') ||
        code.contains('SEAT_HELD')) {
      return l10n?.errorSeatAlreadyBooked ??
          (isAr
              ? 'المقعد محجوز بالفعل. اختر مقعدًا آخر.'
              : 'This seat is already booked. Please choose another seat.');
    }
    if (code.contains('HOLD_EXPIRED')) {
      return l10n?.holdExpiredNotice ??
          (isAr
              ? 'انتهت مدة حجز المقعد. اختر المقعد مرة أخرى.'
              : 'Your seat hold has expired. Please select a seat again.');
    }
    if (code.contains('INSUFFICIENT_POINTS') ||
        code.contains('INSUFFICIENT_BALANCE')) {
      return l10n?.insufficientPointsNotice ??
          (isAr
              ? 'رصيد النقاط غير كافٍ. يرجى شحن النقاط للمتابعة.'
              : 'Insufficient points balance. Please recharge your points to continue.');
    }
    if (code.contains('ROUND_TRIP_MUST_START_WITH_OUTBOUND')) {
      return l10n?.errorRoundTripMustStartWithOutbound ??
          (isAr
              ? 'حجز الذهاب والعودة متاح فقط عند بدء الحجز من اتجاه الذهاب.'
              : 'Round Trip booking is only available when starting from the Outbound direction.');
    }
    if (code.contains('INVALID_ROUND_TRIP_DIRECTIONS')) {
      return l10n?.errorInvalidRoundTripDirections ??
          (isAr
              ? 'يجب أن تكون رحلتا الذهاب والعودة في اتجاهين متعاكسين.'
              : 'Outbound and Return trips must be in opposite directions.');
    }
    if (code.contains('ROUND_TRIP_SAME_DAY_REQUIRED')) {
      return l10n?.errorRoundTripSameDayRequired ??
          (isAr
              ? 'يجب أن تكون رحلتا الذهاب والعودة في نفس اليوم.'
              : 'Outbound and Return trips must be on the same service day.');
    }
    if (code.contains('RETURN_MUST_BE_AFTER_OUTBOUND')) {
      return l10n?.errorReturnMustBeAfterOutbound ??
          (isAr
              ? 'يجب أن يكون موعد رحلة العودة بعد موعد رحلة الذهاب.'
              : 'Return trip departure must be after Outbound departure.');
    }
    if (code.contains('ROUND_TRIP_DISCOUNT_ALREADY_USED_TODAY')) {
      return l10n?.errorRoundTripDiscountAlreadyUsedToday ??
          (isAr
              ? 'لقد استفدت من خصم الذهاب والعودة لهذا اليوم بالفعل.'
              : 'You have already used your daily round-trip discount.');
    }
    if (code.contains('ROUND_TRIP_REQUIRES_UNBOOKED_TRIPS')) {
      return l10n?.errorRoundTripRequiresUnbookedTrips ??
          (isAr
              ? 'لديك حجز مسبق على إحدى الرحلتين المختارتين.'
              : 'You already have a booking on one of the selected trips.');
    }
    if (code.contains('ROUND_TRIP_HOLD_ALREADY_ACTIVE')) {
      return l10n?.errorRoundTripHoldAlreadyActive ??
          (isAr
              ? 'لديك حجز مؤقت نشط لرحلة ذهاب وعودة بالفعل.'
              : 'You already have an active round-trip hold.');
    }
    if (code.contains('ROUND_TRIP_HOLD_NOT_FOUND')) {
      return l10n?.errorRoundTripHoldNotFound ??
          (isAr
              ? 'لم يتم العثور على الحجز المؤقت.'
              : 'Round-trip hold not found.');
    }
    if (code.contains('ROUND_TRIP_HOLD_INVALID') ||
        code.contains('POINT_HOLD_INVALID')) {
      return l10n?.errorRoundTripHoldInvalid ??
          (isAr
              ? 'بيانات حجز الذهاب والعودة غير صحيحة.'
              : 'Round-trip hold is invalid or expired.');
    }
    if (code.contains('RETURN_SEAT_REQUIRED')) {
      return l10n?.errorReturnSeatRequired ??
          (isAr
              ? 'يرجى اختيار مقعد رحلة العودة أولاً.'
              : 'Please select a return seat first.');
    }
    if (code.contains('ROUND_TRIP_CANCELLATION_WINDOW_CLOSED') ||
        code.contains('CANCELLATION_WINDOW_CLOSED')) {
      return l10n?.errorRoundTripCancellationWindowClosed ??
          (isAr
              ? 'تم إغلاق نافذة إلغاء حجز الذهاب والعودة.'
              : 'Cancellation window for this round-trip bundle has closed.');
    }
    if (code.contains('ROUND_TRIP_ALREADY_USED')) {
      return l10n?.errorRoundTripAlreadyUsed ??
          (isAr
              ? 'لا يمكن إلغاء الحجز بعد استخدام إحدى الرحلات أو تسجيل الحضور.'
              : 'Cannot cancel after a trip in the bundle has been checked-in or completed.');
    }
    if (code.contains('ROUND_TRIP_BUNDLE_NOT_CANCELLABLE')) {
      return l10n?.errorRoundTripBundleNotCancellable ??
          (isAr
              ? 'لا يمكن إلغاء هذه الباقة.'
              : 'This bundle is not cancellable.');
    }
    if (code.contains('TRIP_CANCELLED') || code.contains('TRIP_CANCELED')) {
      return l10n?.errorTripCancelled ??
          (isAr
              ? 'تم إلغاء هذه الرحلة.'
              : 'This trip has been cancelled.');
    }
    if (code.contains('TRIP_COMPLETED')) {
      return l10n?.errorTripCompleted ??
          (isAr
              ? 'اكتملت هذه الرحلة بالفعل.'
              : 'This trip has already been completed.');
    }
    if (code.contains('BOOKING_NOT_BOARDABLE')) {
      return l10n?.errorBookingNotBoardable ??
          (isAr
              ? 'هذا الحجز غير مؤهل للصعود حالياً.'
              : 'This booking is not eligible for boarding at this time.');
    }
    if (code.contains('ALREADY_CHECKED_IN')) {
      return l10n?.errorAlreadyCheckedIn ??
          (isAr
              ? 'تم تسجيل الصعود لهذا الحجز مسبقاً.'
              : 'Boarding has already been recorded for this booking.');
    }
    if (code.contains('TOO_EARLY')) {
      return l10n?.errorTooEarly ??
          (isAr
              ? 'موعد الصعود لم يحن بعد.'
              : 'It is too early for boarding.');
    }
    if (code.contains('WRONG_TRIP')) {
      return l10n?.errorWrongTrip ??
          (isAr
              ? 'رمز الصعود لا يطابق هذه الرحلة.'
              : 'The boarding code does not match this trip.');
    }
    if (code.contains('INVALID_TOKEN')) {
      return l10n?.errorInvalidToken ??
          (isAr
              ? 'رمز غير صالح أو منتهي الصلاحية.'
              : 'Invalid or expired boarding token.');
    }
    if (code.contains('BOOKING_CLOSED')) {
      return l10n?.errorBookingClosed ??
          (isAr
              ? 'تم إغلاق الحجز على هذه الرحلة.'
              : 'Booking is closed for this trip.');
    }
    if (code.contains('CHANGE_SEAT_WINDOW_CLOSED')) {
      return l10n?.errorChangeSeatWindowClosed ??
          (isAr
              ? 'تم إغلاق نافذة تغيير المقعد.'
              : 'Seat change window has closed.');
    }
    if (code.contains('SERVICE_DAY_OFF')) {
      return l10n?.errorServiceDayOff ??
          (isAr
              ? 'هذا اليوم عطلة، لا توجد رحلات مجدولة.'
              : 'No trips scheduled for this day.');
    }

    return null;
  }

  /// Logs technical details in debug mode only, safely omitting secrets.
  static void _logTechnicalError(dynamic error) {
    if (!kDebugMode) return;

    try {
      final safeType = error?.runtimeType.toString() ?? 'Null';
      final safeDesc = error?.toString() ?? 'No error description';

      // Never log sensitive user credentials
      if (safeDesc.contains('password') ||
          safeDesc.contains('otp') ||
          safeDesc.contains('secret') ||
          safeDesc.contains('token')) {
        debugPrint('[AppErrorMapper] Technical error caught ($safeType): [REDACTED_CREDENTIALS]');
      } else {
        debugPrint('[AppErrorMapper] Technical error caught ($safeType): $safeDesc');
      }
    } catch (_) {}
  }
}
