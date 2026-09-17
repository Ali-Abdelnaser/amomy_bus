import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amomy_bus/core/error/error_handler.dart';
import 'package:amomy_bus/core/error/failures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorHandler - GoogleSignInException', () {
    test(
      'does not misclassify error 16 reauth failed as user cancellation',
      () {
        const error16 = GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: '[16] Account reauth failed.',
        );

        final failure = ErrorHandler.handle(error16);

        expect(failure, isA<AuthenticationFailure>());
        expect(failure is AuthCancelledFailure, isFalse);
        expect(failure.message, contains('Google'));
      },
    );

    test('properly identifies normal user cancellation', () {
      const normalCancel = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'User dismissed the picker',
      );

      final failure = ErrorHandler.handle(normalCancel);

      expect(failure, isA<AuthCancelledFailure>());
    });
  });

  group('ErrorHandler - AuthException OTP Handling', () {
    test(
      'maps "Token has expired or is invalid" with 403 to incorrect code failure',
      () {
        const authEx = AuthException(
          'Token has expired or is invalid',
          statusCode: '403',
        );
        final failure = ErrorHandler.handle(authEx);

        expect(failure, isA<AuthenticationFailure>());
        expect(failure.statusCode, equals(403));
        expect(
          failure.message,
          anyOf(
            equals('The verification code is incorrect.'),
            equals('رمز التحقق غير صحيح.'),
          ),
        );
      },
    );

    test('maps pure "Token has expired" to expired code failure', () {
      const authEx = AuthException('Token has expired', statusCode: '403');
      final failure = ErrorHandler.handle(authEx);

      expect(failure, isA<AuthenticationFailure>());
      expect(failure.statusCode, equals(403));
      expect(
        failure.message,
        anyOf(
          equals('This code has expired. Request a new one.'),
          equals('انتهت صلاحية هذا الرمز. يرجى طلب رمز جديد.'),
        ),
      );
    });

    test('maps rate limit error with 429 to rate limited failure', () {
      const authEx = AuthException(
        'Email rate limit exceeded',
        statusCode: '429',
      );
      final failure = ErrorHandler.handle(authEx);

      expect(failure, isA<AuthenticationFailure>());
      expect(failure.statusCode, equals(429));
      expect(
        failure.message,
        anyOf(
          equals('Please wait before requesting another code.'),
          equals('يرجى الانتظار قليلاً قبل طلب رمز جديد.'),
        ),
      );
    });

    test('maps SocketException / network errors to NetworkFailure', () {
      final failure = ErrorHandler.handle(
        const SocketException('Failed host lookup: api.supabase.co'),
      );

      expect(failure, isA<NetworkFailure>());
      expect(
        failure.message,
        anyOf(contains('connection'), contains('اتصالك')),
      );
    });
  });
}
