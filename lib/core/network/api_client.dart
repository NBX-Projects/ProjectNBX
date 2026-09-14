import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:projectnbx/features/auth/models/user_model.dart';

class ApiClient {
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _customBaseUrl = null;
    } else {
      var clean = url.trim();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'http://$clean';
      }
      if (!clean.endsWith('/api')) {
        if (clean.endsWith('/')) {
          clean = '${clean}api';
        } else {
          clean = '$clean/api';
        }
      }
      _customBaseUrl = clean;
    }
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://192.168.3.10:8080/api';
    return 'http://localhost:8080/api';
  }

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

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
      final response = await _client.post(
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
      final response = await _client.post(
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

  Future<List<Map<String, dynamic>>> getServers() async {
    final url = Uri.parse('$baseUrl/servers');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createServer(
    String name, {
    String? iconUrl,
  }) async {
    final url = Uri.parse('$baseUrl/servers');
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode({'name': name, 'icon_url': iconUrl ?? ''}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getChannels(String serverId) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/channels');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String serverId,
    String channelId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/servers/$serverId/channels/$channelId/messages',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateMessage(
    String serverId,
    String channelId,
    String messageId,
    String content,
  ) async {
    final url = Uri.parse(
      '$baseUrl/servers/$serverId/channels/$channelId/messages/$messageId',
    );
    try {
      final response = await _client.put(
        url,
        headers: _headers,
        body: jsonEncode({'content': content}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMessage(
    String serverId,
    String channelId,
    String messageId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/servers/$serverId/channels/$channelId/messages/$messageId',
    );
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getServerMembers(String serverId) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/members');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> addServerMember(
    String serverId, {
    String? username,
    String? email,
    String? userId,
  }) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/members');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode({
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
          if (username != null && username.isNotEmpty)
            'username': username.trim(),
          if (email != null && email.isNotEmpty) 'email': email.trim(),
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Falha ao adicionar membro');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> removeServerMember(String serverId, String userId) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/members/$userId');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> joinServer(String codeOrId) async {
    final cleanCode = codeOrId.trim();
    final url = Uri.parse('$baseUrl/servers/$cleanCode/join');
    try {
      final response = await _client.post(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Falha ao entrar no servidor');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createInvite(
    String serverId, {
    int? maxAgeSeconds,
    int? maxUses,
  }) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/invites');
    final payload = <String, dynamic>{};
    if (maxAgeSeconds != null) payload['max_age_seconds'] = maxAgeSeconds;
    if (maxUses != null) payload['max_uses'] = maxUses;

    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Falha ao gerar convite');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getServerInvites(String serverId) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/invites');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteInvite(String serverId, String code) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/invites/$code');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final url = Uri.parse(
      '$baseUrl/users/search?q=${Uri.encodeComponent(query)}',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getVoiceToken(String channelId) async {
    final url = Uri.parse('$baseUrl/voice/token');
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode({'room_name': channelId}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(data?['error'] ?? 'Falha ao obter token do LiveKit');
    }
  }
}
