import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:amomy_bus/core/error/error_handler.dart';
import 'package:amomy_bus/core/error/failures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorHandler - GoogleSignInException', () {
    test('does not misclassify error 16 reauth failed as user cancellation', () {
      const error16 = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '[16] Account reauth failed.',
      );

      final failure = ErrorHandler.handle(error16);

      expect(failure, isA<AuthenticationFailure>());
      expect(failure is AuthCancelledFailure, isFalse);
      expect(
        failure.message,
        contains('Google'),
      );
    });

    test('properly identifies normal user cancellation', () {
      const normalCancel = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'User dismissed the picker',
      );

      final failure = ErrorHandler.handle(normalCancel);

      expect(failure, isA<AuthCancelledFailure>());
    });
  });
}
