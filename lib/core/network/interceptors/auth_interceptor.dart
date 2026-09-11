import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../constants/api_constants.dart';
import '../../constants/storage_keys.dart';
import '../../services/secure_storage_service.dart';

@injectable
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.authToken);
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authorizationHeader] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Session expired or unauthorized
    }
    return handler.next(err);
  }
}
