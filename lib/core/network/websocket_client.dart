import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class WebSocketClient {
  final String wsUrl;
  WebSocket? _socket;
  StreamSubscription? _subscription;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;

  WebSocketClient({this.wsUrl = ApiConstants.wsUrl});

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  void connect({String? token, String? serverId}) async {
    disconnect();

    try {
      final queryParams = <String, String>{};
      if (token != null) queryParams['token'] = token;
      if (serverId != null) queryParams['server_id'] = serverId;

      final uri = queryParams.isEmpty
          ? Uri.parse(wsUrl)
          : Uri.parse(wsUrl).replace(queryParameters: queryParams);

      _socket = await WebSocket.connect(uri.toString()).timeout(const Duration(seconds: 4));
      _isConnected = true;

      _subscription = _socket?.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString()) as Map<String, dynamic>;
            _eventController.add(parsed);
          } catch (e) {
            debugPrint('[WebSocketClient] Erro ao parsear mensagem: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          debugPrint('[WebSocketClient] Conexão WebSocket encerrada.');
        },
        onError: (err) {
          _isConnected = false;
          debugPrint('[WebSocketClient] Erro no canal WebSocket: $err');
        },
      );
    } catch (e) {
      _isConnected = false;
      debugPrint('[WebSocketClient] Falha ao conectar no WebSocket: $e');
    }
  }

  void sendEvent(String type, Map<String, dynamic> payload, {String? channelId, String? serverId}) {
    if (!_isConnected || _socket == null) return;

    try {
      final eventMap = <String, dynamic>{
        'type': type,
        'payload': payload,
      };
      if (channelId != null) eventMap['channel_id'] = channelId;
      if (serverId != null) eventMap['server_id'] = serverId;

      _socket?.add(jsonEncode(eventMap));
    } catch (e) {
      debugPrint('[WebSocketClient] Erro ao enviar evento: $e');
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
