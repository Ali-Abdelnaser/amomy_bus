class ApiConstants {
  const ApiConstants._();

  // Endpoints & paths (placeholders for REST / Edge functions / GPS API)
  static const String baseApiUrl = 'https://api.amomybus.com/v1';
  static const String gpsProviderBaseUrl = 'https://gps.amomybus.com/api';

  // Header keys
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String jsonContentType = 'application/json';
}
