import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:projectnbx/features/voice/services/screen_capture_source.dart';

enum ScreenShareRole { broadcaster, viewer }

enum ScreenShareConnectionState {
  idle,
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed,
  closed,
}

class ScreenShareSession {
  final String sessionId;
  final String channelId;
  final String broadcasterId;
  final ScreenShareRole role;
  final ScreenQualityProfile profile;
  final DateTime startedAt;

  const ScreenShareSession({
    required this.sessionId,
    required this.channelId,
    required this.broadcasterId,
    required this.role,
    required this.profile,
    required this.startedAt,
  });
}

class ScreenShareConnection {
  final String sessionId;
  final String peerId;
  final MediaStream? stream;
  final ScreenShareConnectionState state;

  const ScreenShareConnection({
    required this.sessionId,
    required this.peerId,
    this.stream,
    required this.state,
  });

  ScreenShareConnection copyWith({
    String? sessionId,
    String? peerId,
    MediaStream? stream,
    ScreenShareConnectionState? state,
  }) {
    return ScreenShareConnection(
      sessionId: sessionId ?? this.sessionId,
      peerId: peerId ?? this.peerId,
      stream: stream ?? this.stream,
      state: state ?? this.state,
    );
  }
}

class RemoteScreenShare {
  final String sessionId;
  final String channelId;
  final String broadcasterId;
  final MediaStream stream;
  final String quality;
  final DateTime startedAt;

  const RemoteScreenShare({
    required this.sessionId,
    required this.channelId,
    required this.broadcasterId,
    required this.stream,
    required this.quality,
    required this.startedAt,
  });
}

/// Contrato abstrato e plugável de transporte de compartilhamento de tela
abstract class ScreenShareTransport {
  Future<ScreenShareSession> startBroadcast({
    required String channelId,
    required MediaStream stream,
    required ScreenQualityProfile profile,
  });

  Future<void> stopBroadcast();

  Future<ScreenShareConnection> connectTo({
    required String sessionId,
    required String broadcasterId,
  });

  Future<void> disconnectFrom({
    required String sessionId,
  });

  Stream<RemoteScreenShare?> get remoteStreamStream;
  Stream<ScreenShareConnectionState> get connectionStateStream;
  Stream<Map<String, dynamic>> get statsStream;

  void dispose();
}
