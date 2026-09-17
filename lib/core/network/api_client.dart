import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/network/api_offline_exception.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/servers/models/public_server_model.dart';
import 'package:projectnbx/features/servers/models/server_join_request_model.dart';
import 'package:projectnbx/features/servers/models/server_role_model.dart';

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
    if (!kIsWeb &&
        Platform.isAndroid &&
        AppConfig.isDev &&
        AppConfig.apiBaseUrl.contains('localhost')) {
      return AppConfig.apiBaseUrl.replaceAll('localhost', '10.0.2.2');
    }
    return AppConfig.apiBaseUrl;
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

  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response =
          await _client.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
    } catch (_) {}

    try {
      final altUrl = Uri.parse('$baseUrl/api/health');
      final altResp =
          await _client.get(altUrl).timeout(const Duration(seconds: 4));
      return altResp.statusCode >= 200 && altResp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResponse> login(String login, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await _client
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'login': login.trim(),
              'email': login.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 500) {
        throw ApiOfflineException(
          'Servidor backend offline (${response.statusCode} Bad Gateway/Erro de Servidor).',
          response.statusCode,
        );
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiOfflineException(
          'Servidor backend offline ou resposta inválida (${response.statusCode}).',
          response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final authRes = AuthResponse.fromJson(data);
        _authToken = authRes.token;
        return authRes;
      } else {
        throw Exception(data['error'] ?? 'Falha ao autenticar');
      }
    } catch (e) {
      if (e is ApiOfflineException) rethrow;
      if (e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('recusou a conexão') ||
          e.toString().contains('TimeoutException')) {
        throw const ApiOfflineException(
          'Servidor backend offline. Não foi possível conectar ao endereço da API.',
        );
      }
      rethrow;
    }
  }

  Future<AuthResponse> register(
    String username,
    String email,
    String password, {
    String? name,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await _client
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'name': (name != null && name.trim().isNotEmpty)
                  ? name.trim()
                  : username.trim(),
              'username': username.trim(),
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 500) {
        throw ApiOfflineException(
          'Servidor backend offline (${response.statusCode} Bad Gateway/Erro de Servidor).',
          response.statusCode,
        );
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiOfflineException(
          'Servidor backend offline ou resposta inválida (${response.statusCode}).',
          response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final authRes = AuthResponse.fromJson(data);
        _authToken = authRes.token;
        return authRes;
      } else {
        throw Exception(data['error'] ?? 'Falha ao criar conta');
      }
    } catch (e) {
      if (e is ApiOfflineException) rethrow;
      if (e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('recusou a conexão') ||
          e.toString().contains('TimeoutException')) {
        throw const ApiOfflineException(
          'Servidor backend offline. Não foi possível conectar ao endereço da API.',
        );
      }
      rethrow;
    }
  }

  Future<UserModel> updateProfile({
    required String name,
    required String username,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/users/me');
    try {
      final response = await _client.put(
        url,
        headers: _headers,
        body: jsonEncode({
          'name': name.trim(),
          'username': username.trim(),
          'email': email.trim(),
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return UserModel.fromJson(data);
      } else {
        throw Exception(data['error'] ?? 'Falha ao atualizar perfil');
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/users/me/password');
    try {
      final response = await _client.put(
        url,
        headers: _headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception(data['error'] ?? 'Falha ao alterar senha');
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
      final response =
          await _client.get(url, headers: _headers).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode >= 500) {
        throw ApiOfflineException(
          'Servidor backend offline (Status ${response.statusCode} Bad Gateway/Erro no Servidor).',
          response.statusCode,
        );
      } else {
        return [];
      }
    } catch (e) {
      if (e is ApiOfflineException) rethrow;
      if (e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('recusou a conexão') ||
          e.toString().contains('TimeoutException')) {
        throw const ApiOfflineException(
          'Servidor backend offline. Não foi possível carregar os servidores.',
        );
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> createServer(
    String name, {
    String? iconUrl,
    bool isPublic = false,
    String? description,
    String? category,
  }) async {
    final url = Uri.parse('$baseUrl/servers');
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'icon_url': iconUrl ?? '',
        'is_public': isPublic,
        'description': description ?? '',
        'category': category ?? 'Comunidade Geral',
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateServer(
    String serverId, {
    String? name,
    String? iconUrl,
    bool? isPublic,
    String? description,
    String? category,
  }) async {
    final url = Uri.parse('$baseUrl/servers/$serverId');
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (iconUrl != null) payload['icon_url'] = iconUrl.trim();
    if (isPublic != null) payload['is_public'] = isPublic;
    if (description != null) payload['description'] = description.trim();
    if (category != null) payload['category'] = category.trim();

    try {
      final response = await _client.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
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

  Future<Map<String, dynamic>> getTURNCredentials() async {
    final url = Uri.parse('$baseUrl/webrtc/turn-credentials');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // ==========================================
  // Servidores Públicos & Descoberta
  // ==========================================

  Future<List<PublicServerModel>> getPublicServers() async {
    final url = Uri.parse('$baseUrl/servers/public');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data
            .map((item) =>
                PublicServerModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // Pedidos de Entrada (Join Requests)
  // ==========================================

  Future<ServerJoinRequestModel?> createJoinRequest(
    String serverId, {
    String message = '',
  }) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/join-requests');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode({'message': message}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ServerJoinRequestModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(
            data?['error'] ?? 'Falha ao solicitar entrada no servidor');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ServerJoinRequestModel>> getJoinRequests(
    String serverId, {
    String status = 'pending',
  }) async {
    final url =
        Uri.parse('$baseUrl/servers/$serverId/join-requests?status=$status');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data
            .map((item) =>
                ServerJoinRequestModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> reviewJoinRequest(
    String serverId,
    String requestId, {
    required bool approve,
  }) async {
    final url =
        Uri.parse('$baseUrl/servers/$serverId/join-requests/$requestId/review');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode({'status': approve ? 'approved' : 'rejected'}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // Cargos & Permissões (Roles)
  // ==========================================

  Future<List<ServerRoleModel>> getServerRoles(String serverId) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/roles');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as List<dynamic>? ?? [];
        return data
            .map((item) =>
                ServerRoleModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ServerRoleModel?> createServerRole(
    String serverId, {
    required String name,
    int color = 0xFFF5CBA7,
    int position = 0,
    Map<String, bool> permissions = const {},
  }) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/roles');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'color': color,
          'position': position,
          'permissions': permissions,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ServerRoleModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Falha ao criar cargo');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ServerRoleModel?> updateServerRole(
    String serverId,
    String roleId, {
    required String name,
    int? color,
    int? position,
    Map<String, bool>? permissions,
  }) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/roles/$roleId');
    try {
      final payload = <String, dynamic>{'name': name};
      if (color != null) payload['color'] = color;
      if (position != null) payload['position'] = position;
      if (permissions != null) payload['permissions'] = permissions;

      final response = await _client.put(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ServerRoleModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Falha ao atualizar cargo');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteServerRole(String serverId, String roleId) async {
    final url = Uri.parse('$baseUrl/servers/$serverId/roles/$roleId');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignMemberRole(
    String serverId,
    String userId,
    String roleId,
  ) async {
    final url =
        Uri.parse('$baseUrl/servers/$serverId/members/$userId/roles/$roleId');
    try {
      final response = await _client.post(url, headers: _headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeMemberRole(
    String serverId,
    String userId,
    String roleId,
  ) async {
    final url =
        Uri.parse('$baseUrl/servers/$serverId/members/$userId/roles/$roleId');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
