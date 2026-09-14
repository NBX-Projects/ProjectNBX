import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final websocketClientProvider = Provider<WebSocketClient>((ref) {
  final apiClient = ref.watch<ApiClient>(apiClientProvider);
  final client = WebSocketClient(apiClient, ref);

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
  final Ref? _ref;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _isDisposed = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentServerId;

  final List<String> _pendingOutgoingQueue = [];
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  WebSocketClient(this._apiClient, [this._ref]);

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  bool get isConnected => _isConnected && _channel != null;

  Future<void> connect({String? serverId}) async {
    if (_isDisposed) return;

    if (serverId != null && serverId.isNotEmpty) {
      _currentServerId = serverId;
    }

    // Se já estiver conectando ou já estiver conectado com canal ativo, não duplica conexão
    if (_isConnecting || (_channel != null && _isConnected)) {
      return;
    }

    _isConnecting = true;
    _reconnectTimer?.cancel();

    try {
      var token = _ref?.read(authControllerProvider).token ?? _apiClient.authToken ?? '';
      if (token.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('auth_token') ?? '';
          if (token.isNotEmpty) {
            _apiClient.setAuthToken(token);
          }
        } catch (_) {}
      }

      if (token.isEmpty) {
        debugPrint('[WebSocket] Conexão cancelada: token de autenticação ausente.');
        _isConnecting = false;
        return;
      }

      // Fecha conexão anterior se existia
      _disconnectInternal(silent: true);

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

      debugPrint('[WebSocket] Conectando a $wsUri');

      final channel = WebSocketChannel.connect(wsUri);
      _channel = channel;
      _isConnecting = false;
      _isConnected = true;

      channel.ready.then((_) {
        _isConnected = true;
        _flushPendingQueue();
      }).catchError((Object e) {
        debugPrint('[WebSocket] Erro na verificação ready do socket: $e');
      });

      _subscription = channel.stream.listen(
        (data) {
          _isConnecting = false;
          _isConnected = true;
          try {
            final decoded = jsonDecode(data.toString());
            if (decoded is Map) {
              final mapped = Map<String, dynamic>.from(decoded);
              _eventController.add(mapped);
            }
          } catch (e) {
            debugPrint('[WebSocket] Erro ao decodificar mensagem: $e');
          }
        },
        onError: (Object error) {
          _isConnecting = false;
          _isConnected = false;
          debugPrint('[WebSocket] Erro na conexão: $error');
          _handleDisconnect();
        },
        onDone: () {
          _isConnecting = false;
          _isConnected = false;
          debugPrint('[WebSocket] Conexão encerrada');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      _startPing();
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      debugPrint('[WebSocket] Falha ao conectar: $e');
      _handleDisconnect();
    }
  }

  void _flushPendingQueue() {
    if (_channel == null || _pendingOutgoingQueue.isEmpty) return;
    final queueCopy = List<String>.from(_pendingOutgoingQueue);
    _pendingOutgoingQueue.clear();
    for (final msg in queueCopy) {
      try {
        _channel!.sink.add(msg);
      } catch (e) {
        debugPrint('[WebSocket] Erro ao enviar mensagem da fila: $e');
      }
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_channel != null) {
        sendEvent('PING', <String, dynamic>{});
      }
    });
  }

  void _handleDisconnect() {
    _disconnectInternal();
    if (_isDisposed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_isDisposed && _channel == null) {
        debugPrint('[WebSocket] Tentando reconectar...');
        connect(serverId: _currentServerId);
      }
    });
  }

  void sendEvent(String type, dynamic payload,
      {String? channelId, String? serverId}) {
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

      if (_channel != null) {
        _channel!.ready.then((_) {
          _channel?.sink.add(msg);
        }).catchError((Object _) {
          _channel?.sink.add(msg);
        });
      } else {
        _pendingOutgoingQueue.add(msg);
        connect(serverId: serverId ?? _currentServerId);
      }
    } catch (e) {
      debugPrint('[WebSocket] Erro ao enviar mensagem: $e');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _currentServerId = null;
    _disconnectInternal();
  }

  void _disconnectInternal({bool silent = false}) {
    _pingTimer?.cancel();
    _isConnected = false;
    if (!silent) {
      _isConnecting = false;
    }
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
  }
}
