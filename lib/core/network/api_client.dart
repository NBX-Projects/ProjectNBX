import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiClient {
  final String baseUrl;
  String? _authToken;

  ApiClient({this.baseUrl = ApiConstants.baseUrl});

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool needsAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needsAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Verifica se o backend em Go está online e saudável
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl${ApiConstants.healthEndpoint}'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiClient] Backend Go offline ou inacessível: $e');
      return false;
    }
  }

  /// Autentica usuário e armazena o token de sessão
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.loginEndpoint}'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        return data;
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro no login: $e');
    }
    return null;
  }

  /// Registra um novo usuário
  Future<Map<String, dynamic>?> register(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.registerEndpoint}'),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        return data;
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro no registro: $e');
    }
    return null;
  }

  /// Solicita ao backend Go a geração de um Token de Acesso LiveKit SFU (WebRTC)
  Future<Map<String, dynamic>?> getVoiceToken({
    required String roomName,
    String? participantName,
    String? identity,
  }) async {
    try {
      final body = <String, dynamic>{'room_name': roomName};
      if (participantName != null) body['participant_name'] = participantName;
      if (identity != null) body['identity'] = identity;

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.voiceTokenEndpoint}'),
        headers: _headers(needsAuth: _authToken != null),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro ao obter token LiveKit do Go backend: $e');
    }
    return null;
  }
}
