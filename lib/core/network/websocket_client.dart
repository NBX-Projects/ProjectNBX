import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final websocketClientProvider = Provider<WebSocketClient>((ref) {
  final apiClient = ref.watch<ApiClient>(apiClientProvider);
  final client = WebSocketClient(apiClient);

  final initialAuth = ref.read(authControllerProvider);
  if (initialAuth.isAuthenticated) {
    if (initialAuth.token != null) {
      apiClient.setAuthToken(initialAuth.token);
    }
    client.connect();
  }

  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (next.isAuthenticated) {
      if (next.token != null) {
        apiClient.setAuthToken(next.token);
      }
      client.connect();
    } else {
      client.disconnect();
    }
  });

  ref.onDispose(() {
    client.dispose();
  });
  return client;
});

class WebSocketClient {
  final ApiClient _apiClient;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _isDisposed = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentServerId;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  WebSocketClient(this._apiClient);

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  bool get isConnected => _isConnected;

  void connect({String? serverId}) {
    if (_isDisposed) return;

    if (serverId != null && serverId.isNotEmpty) {
      _currentServerId = serverId;
    }

    final token = _apiClient.authToken ?? '';
    if (token.isEmpty) {
      dev.log('[WebSocket] Conexão cancelada: token de autenticação ausente.',
          name: 'WebSocketClient');
      return;
    }

    // Se a conexão já estiver ativa OU em andamento, apenas atualiza o servidor atual e mantém a conexão aberta
    if (_isConnected || _isConnecting) {
      return;
    }

    _reconnectTimer?.cancel();
    _disconnectInternal();
    _isConnecting = true;

    try {
      final baseUri = Uri.parse(ApiClient.baseUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';

      final wsUri = Uri(
        scheme: wsScheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: '/ws',
        queryParameters: {
          'token': token,
          if (_currentServerId != null && _currentServerId!.isNotEmpty)
            'server_id': _currentServerId!,
        },
      );

      dev.log('[WebSocket] Conectando a $wsUri', name: 'WebSocketClient');

      _channel = WebSocketChannel.connect(wsUri);

      _subscription = _channel!.stream.listen(
        (data) {
          _isConnecting = false;
          _isConnected = true;
          try {
            final decoded = jsonDecode(data.toString());
            if (decoded is Map<String, dynamic>) {
              _eventController.add(decoded);
            }
          } catch (e) {
            dev.log('[WebSocket] Erro ao decodificar mensagem: $e',
                name: 'WebSocketClient');
          }
        },
        onError: (Object error) {
          _isConnecting = false;
          dev.log('[WebSocket] Erro na conexão: $error',
              name: 'WebSocketClient');
          _handleDisconnect();
        },
        onDone: () {
          _isConnecting = false;
          dev.log('[WebSocket] Conexão encerrada', name: 'WebSocketClient');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      _startPing();
    } catch (e) {
      _isConnecting = false;
      dev.log('[WebSocket] Falha ao conectar: $e', name: 'WebSocketClient');
      _handleDisconnect();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _channel != null) {
        sendEvent('PING', <String, dynamic>{});
      }
    });
  }

  void _handleDisconnect() {
    _disconnectInternal();
    if (_isDisposed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed && !_isConnected) {
        dev.log('[WebSocket] Tentando reconectar...', name: 'WebSocketClient');
        connect(serverId: _currentServerId);
      }
    });
  }

  void sendEvent(String type, dynamic payload,
      {String? channelId, String? serverId}) {
    if (_channel == null || !_isConnected) return;

    try {
      final payloadMap = <String, dynamic>{
        'type': type,
        'payload': payload,
      };
      if (channelId != null) {
        payloadMap['channel_id'] = channelId;
      }
      if (serverId != null || _currentServerId != null) {
        payloadMap['server_id'] = serverId ?? _currentServerId;
      }
      final msg = jsonEncode(payloadMap);
      _channel!.sink.add(msg);
    } catch (e) {
      dev.log('[WebSocket] Erro ao enviar mensagem: $e',
          name: 'WebSocketClient');
    }
  }

  void _disconnectInternal() {
    _isConnected = false;
    _isConnecting = false;
    _pingTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _disconnectInternal();
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
  }
}
