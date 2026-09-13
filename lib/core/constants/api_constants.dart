class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
  static const String wsUrl = 'ws://localhost:8080/ws';
  static const String defaultLiveKitUrl = 'ws://localhost:7880';

  // Endpoints REST
  static const String healthEndpoint = '/api/health';
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';
  static const String meEndpoint = '/api/auth/me';
  static const String voiceTokenEndpoint = '/api/voice/token';
  static const String serversEndpoint = '/api/servers';
}
