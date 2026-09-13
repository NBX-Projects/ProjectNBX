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
    String username,
    String email,
    String password,
  ) async {
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

  /// Lista todos os servidores reais do backend Go
  Future<List<Map<String, dynamic>>> listServers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConstants.serversEndpoint}'),
        headers: _headers(needsAuth: _authToken != null),
      );

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro ao listar servidores: $e');
    }
    return [];
  }

  /// Cria um novo servidor no backend Go
  Future<Map<String, dynamic>?> createServer(
    String name, {
    String? iconUrl,
  }) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (iconUrl != null) body['icon_url'] = iconUrl;

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.serversEndpoint}'),
        headers: _headers(needsAuth: _authToken != null),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro ao criar servidor: $e');
    }
    return null;
  }

  /// Lista canais de um servidor
  Future<List<Map<String, dynamic>>> listChannels(String serverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConstants.serversEndpoint}/$serverId/channels'),
        headers: _headers(needsAuth: _authToken != null),
      );

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro ao listar canais: $e');
    }
    return [];
  }

  /// Cria um canal em um servidor
  Future<Map<String, dynamic>?> createChannel(
    String serverId,
    String name,
    String type,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.serversEndpoint}/$serverId/channels'),
        headers: _headers(needsAuth: _authToken != null),
        body: jsonEncode({'name': name, 'type': type}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro ao criar canal: $e');
    }
    return null;
  }

  /// Lista histórico de mensagens de um canal
  Future<List<Map<String, dynamic>>> listMessages(
    String serverId,
    String channelId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl${ApiConstants.serversEndpoint}/$serverId/channels/$channelId/messages',
        ),
        headers: _headers(needsAuth: _authToken != null),
      );

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro ao listar mensagens: $e');
    }
    return [];
  }

  /// Envia mensagem no canal via REST
  Future<Map<String, dynamic>?> sendMessage(
    String serverId,
    String channelId,
    String content,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl${ApiConstants.serversEndpoint}/$serverId/channels/$channelId/messages',
        ),
        headers: _headers(needsAuth: _authToken != null),
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiClient] Erro ao enviar mensagem: $e');
    }
    return null;
  }
}
