import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:projectnbx/features/auth/models/user_model.dart';

class ApiClient {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<AuthResponse> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final authRes = AuthResponse.fromJson(data);
        _authToken = authRes.token;
        return authRes;
      } else {
        throw Exception(data['error'] ?? 'Falha ao autenticar');
      }
    } catch (e) {
      if (e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
          'Servidor backend offline (localhost:8080). Verifique se o backend Go está em execução.',
        );
      }
      rethrow;
    }
  }

  Future<AuthResponse> register(
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final authRes = AuthResponse.fromJson(data);
        _authToken = authRes.token;
        return authRes;
      } else {
        throw Exception(data['error'] ?? 'Falha ao criar conta');
      }
    } catch (e) {
      if (e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
          'Servidor backend offline (localhost:8080). Verifique se o backend Go está em execução.',
        );
      }
      rethrow;
    }
  }
}
