import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:justtalking/core/network/api_client.dart';
import 'package:justtalking/core/network/websocket_client.dart';
import 'package:justtalking/features/voice/services/screen_capture_source.dart';
import 'package:justtalking/features/voice/services/screen_share_transport.dart';

/// Implementação do transporte de Screen Sharing via WebRTC P2P Mesh
class P2PWebRTCScreenTransport implements ScreenShareTransport {
  final WebSocketClient _wsClient;
  final ApiClient _apiClient;

  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  Timer? _statsTimer;

  ScreenShareSession? _broadcastSession;
  final Map<String, ScreenShareSession> _viewerSessions = {};
  MediaStream? _localStream;

  // Mapa de conexões P2P indexadas por Peer ID (Viewer ID no host, ou Broadcaster ID no viewer)
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, int> _iceRestartAttempts = {};
  final Map<String, bool> _makingOffer = {};
  final Map<String, bool> _ignoreOffer = {};

  final _remoteStreamController = StreamController<RemoteScreenShare?>.broadcast();
  final _connectionStateController = StreamController<ScreenShareConnectionState>.broadcast();
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();

  RemoteScreenShare? _activeRemoteShare;
  ScreenShareConnectionState _lastState = ScreenShareConnectionState.idle;

  P2PWebRTCScreenTransport({
    required WebSocketClient wsClient,
    required ApiClient apiClient,
  })  : _wsClient = wsClient,
        _apiClient = apiClient {
    _initWebSocketListener();
  }

  @override
  Stream<RemoteScreenShare?> get remoteStreamStream => _remoteStreamController.stream;

  @override
  Stream<ScreenShareConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  void _updateConnectionState(ScreenShareConnectionState newState) {
    if (_lastState != newState) {
      _lastState = newState;
      _connectionStateController.add(newState);
    }
  }

  void _initWebSocketListener() {
    _wsSubscription = _wsClient.eventStream.listen((event) {
      final type = event['type'] as String?;
      final payloadRaw = event['payload'];
      final channelId = event['channel_id'] as String?;

      if (type == null) return;

      Map<String, dynamic> payload = {};
      if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      } else if (payloadRaw is String && payloadRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(payloadRaw);
          if (decoded is Map) {
            payload = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      _handleIncomingWSEvent(type, payload, channelId);
    });
  }

  Future<Map<String, dynamic>> _getRtcConfiguration() async {
    final iceServers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ];

    try {
      final turnCreds = await _apiClient.getTURNCredentials();
      final urls = turnCreds['urls'] as List<dynamic>?;
      final username = turnCreds['username'] as String?;
      final credential = turnCreds['credential'] as String?;

      if (urls != null && urls.isNotEmpty && username != null && credential != null) {
        iceServers.add({
          'urls': urls,
          'username': username,
          'credential': credential,
        });
      }
    } catch (_) {}

    return {
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
  }

  void _handleIncomingWSEvent(String type, Map<String, dynamic> payload, String? channelId) {
    switch (type) {
      case 'SCREEN_SHARE_STARTED':
        final sessionId = payload['session_id'] as String?;
        if (sessionId != null && _broadcastSession != null) {
          _broadcastSession = ScreenShareSession(
            sessionId: sessionId,
            channelId: _broadcastSession!.channelId,
            broadcasterId: _broadcastSession!.broadcasterId,
            role: ScreenShareRole.broadcaster,
            profile: _broadcastSession!.profile,
            startedAt: DateTime.now(),
          );
          _updateConnectionState(ScreenShareConnectionState.connected);
          _startStatsMonitoring();
        }
        break;

      case 'SCREEN_SHARE_VIEWER_JOINED':
        final viewerId = payload['viewer_id'] as String?;
        final sessionId = payload['session_id'] as String?;
        if (viewerId != null && sessionId != null && _broadcastSession != null) {
          _onViewerJoined(viewerId, sessionId);
        }
        break;

      case 'SCREEN_SHARE_VIEWER_LEFT':
        final viewerId = payload['viewer_id'] as String?;
        if (viewerId != null) {
          _cleanupPeerConnection(viewerId);
        }
        break;

      case 'SCREEN_SHARE_STOPPED':
        final sessionId = payload['session_id'] as String?;
        if (_broadcastSession?.sessionId == sessionId) {
          stopBroadcast();
        } else if (_viewerSessions.containsKey(sessionId) || _activeRemoteShare?.sessionId == sessionId) {
          _handleRemoteSessionStopped(sessionId ?? '');
        }
        break;

      case 'WEBRTC_OFFER':
        _handleWebRTCOffer(payload);
        break;

      case 'WEBRTC_ANSWER':
        _handleWebRTCAnswer(payload);
        break;

      case 'WEBRTC_ICE_CANDIDATE':
        _handleWebRTCICECandidate(payload);
        break;
    }
  }

  @override
  Future<ScreenShareSession> startBroadcast({
    required String channelId,
    required MediaStream stream,
    required ScreenQualityProfile profile,
  }) async {
    _localStream = stream;
    _updateConnectionState(ScreenShareConnectionState.connecting);

    final session = ScreenShareSession(
      sessionId: '', // será atualizado na resposta SCREEN_SHARE_STARTED
      channelId: channelId,
      broadcasterId: '',
      role: ScreenShareRole.broadcaster,
      profile: profile,
      startedAt: DateTime.now(),
    );
    _broadcastSession = session;

    _wsClient.sendEvent(
      'SCREEN_SHARE_START',
      {
        'channel_id': channelId,
        'quality': profile.label.toLowerCase(),
      },
      channelId: channelId,
    );

    return session;
  }

  @override
  Future<void> stopBroadcast() async {
    if (_broadcastSession != null && _broadcastSession!.sessionId.isNotEmpty) {
      _wsClient.sendEvent(
        'SCREEN_SHARE_STOP',
        {
          'session_id': _broadcastSession!.sessionId,
          'channel_id': _broadcastSession!.channelId,
        },
        channelId: _broadcastSession!.channelId,
      );
    }

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
    }
    _broadcastSession = null;

    if (_viewerSessions.isEmpty) {
      _updateConnectionState(ScreenShareConnectionState.idle);
    }
  }

  @override
  Future<ScreenShareConnection> connectTo({
    required String sessionId,
    required String broadcasterId,
  }) async {
    _updateConnectionState(ScreenShareConnectionState.connecting);

    final session = ScreenShareSession(
      sessionId: sessionId,
      channelId: '',
      broadcasterId: broadcasterId,
      role: ScreenShareRole.viewer,
      profile: ScreenQualityProfile.medium,
      startedAt: DateTime.now(),
    );
    _viewerSessions[sessionId] = session;

    _wsClient.sendEvent(
      'SCREEN_SHARE_JOIN',
      {
        'session_id': sessionId,
      },
    );

    return ScreenShareConnection(
      sessionId: sessionId,
      peerId: broadcasterId,
      state: ScreenShareConnectionState.connecting,
    );
  }

  @override
  Future<void> disconnectFrom({required String sessionId}) async {
    final session = _viewerSessions.remove(sessionId);
    if (session != null) {
      _cleanupPeerConnection(session.broadcasterId);
    }
    if (_activeRemoteShare?.sessionId == sessionId) {
      _activeRemoteShare = null;
      _remoteStreamController.add(null);
    }
    if (_broadcastSession == null && _viewerSessions.isEmpty) {
      _updateConnectionState(ScreenShareConnectionState.closed);
    }
  }

  Future<RTCPeerConnection> _createPeerConnectionFor(String peerId, {required bool isPolite}) async {
    final rtcConfig = await _getRtcConfiguration();
    final pc = await createPeerConnection(rtcConfig);

    _peerConnections[peerId] = pc;
    _iceRestartAttempts[peerId] = 0;
    _makingOffer[peerId] = false;
    _ignoreOffer[peerId] = false;

    // Se formos o broadcaster para esta conexão, adicionamos as tracks do stream local
    if (!isPolite && _localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        String sessId = _broadcastSession?.sessionId ?? '';
        if (isPolite) {
          final foundSess = _viewerSessions.values.firstWhere(
            (s) => s.broadcasterId == peerId,
            orElse: () => _viewerSessions.values.isNotEmpty
                ? _viewerSessions.values.first
                : ScreenShareSession(
                    sessionId: '',
                    channelId: '',
                    broadcasterId: '',
                    role: ScreenShareRole.viewer,
                    profile: ScreenQualityProfile.medium,
                    startedAt: DateTime.fromMillisecondsSinceEpoch(0),
                  ),
          );
          if (foundSess.sessionId.isNotEmpty) {
            sessId = foundSess.sessionId;
          }
        }
        _wsClient.sendEvent('WEBRTC_ICE_CANDIDATE', {
          'session_id': sessId,
          'to_user_id': peerId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        String sessId = '';
        final found = _viewerSessions.values.where((s) => s.broadcasterId == peerId);
        if (found.isNotEmpty) {
          sessId = found.first.sessionId;
        }
        _activeRemoteShare = RemoteScreenShare(
          sessionId: sessId,
          channelId: found.isNotEmpty ? found.first.channelId : '',
          broadcasterId: peerId,
          stream: stream,
          quality: 'auto',
          startedAt: DateTime.now(),
        );
        _remoteStreamController.add(_activeRemoteShare);
        _updateConnectionState(ScreenShareConnectionState.connected);
        _startStatsMonitoring();
      }
    };

    pc.onConnectionState = (state) {
      debugPrint('[WebRTC P2P] Peer $peerId ConnectionState: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _updateConnectionState(ScreenShareConnectionState.connected);
        _iceRestartAttempts[peerId] = 0;
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _updateConnectionState(ScreenShareConnectionState.disconnected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _handleIceFailure(peerId, pc);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _updateConnectionState(ScreenShareConnectionState.closed);
      }
    };

    return pc;
  }

  void _onViewerJoined(String viewerId, String sessionId) async {
    // Broadcaster é impolite (isPolite = false)
    final pc = await _createPeerConnectionFor(viewerId, isPolite: false);
    _makingOffer[viewerId] = true;
    try {
      final offer = await pc.createOffer();
      final mungedSdp = _mungeSDP(offer.sdp ?? '');
      final mungedOffer = RTCSessionDescription(mungedSdp, offer.type);
      await pc.setLocalDescription(mungedOffer);

      _wsClient.sendEvent('WEBRTC_OFFER', {
        'session_id': sessionId,
        'to_user_id': viewerId,
        'sdp': mungedSdp,
      });
    } catch (e) {
      debugPrint('[WebRTC P2P] Erro ao criar offer para $viewerId: $e');
    } finally {
      _makingOffer[viewerId] = false;
    }
  }

  void _handleWebRTCOffer(Map<String, dynamic> payload) async {
    final fromUserId = payload['from_user_id'] as String?;
    final sdp = payload['sdp'] as String?;
    final sessionId = payload['session_id'] as String?;

    if (fromUserId == null || sdp == null) return;

    // Viewer é polite (isPolite = true)
    var pc = _peerConnections[fromUserId];
    pc ??= await _createPeerConnectionFor(fromUserId, isPolite: true);

    final isPolite = _viewerSessions.values.any((s) => s.broadcasterId == fromUserId);
    final offerCollision = (_makingOffer[fromUserId] ?? false) ||
        pc.signalingState != RTCSignalingState.RTCSignalingStateStable;

    _ignoreOffer[fromUserId] = !isPolite && offerCollision;
    if (_ignoreOffer[fromUserId] == true) {
      debugPrint('[WebRTC P2P] Oferta colidida ignorada (impolite peer)');
      return;
    }

    try {
      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
      final answer = await pc.createAnswer();
      final mungedAnswerSdp = _mungeSDP(answer.sdp ?? '');
      final mungedAnswer = RTCSessionDescription(mungedAnswerSdp, answer.type);
      await pc.setLocalDescription(mungedAnswer);

      _wsClient.sendEvent('WEBRTC_ANSWER', {
        'session_id': sessionId ?? '',
        'to_user_id': fromUserId,
        'sdp': mungedAnswerSdp,
      });
    } catch (e) {
      debugPrint('[WebRTC P2P] Erro ao processar offer de $fromUserId: $e');
    }
  }

  void _handleWebRTCAnswer(Map<String, dynamic> payload) async {
    final fromUserId = payload['from_user_id'] as String?;
    final sdp = payload['sdp'] as String?;

    if (fromUserId == null || sdp == null) return;

    final pc = _peerConnections[fromUserId];
    if (pc != null && !(_ignoreOffer[fromUserId] ?? false)) {
      try {
        await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
      } catch (e) {
        debugPrint('[WebRTC P2P] Erro ao setRemoteDescription Answer de $fromUserId: $e');
      }
    }
  }

  void _handleWebRTCICECandidate(Map<String, dynamic> payload) async {
    final fromUserId = payload['from_user_id'] as String?;
    final candData = payload['candidate'];

    if (fromUserId == null || candData is! Map) return;

    final pc = _peerConnections[fromUserId];
    if (pc != null) {
      try {
        final candidateStr = candData['candidate'] as String?;
        final sdpMid = candData['sdpMid'] as String?;
        final sdpMLineIndex = candData['sdpMLineIndex'] as int?;

        if (candidateStr != null && candidateStr.isNotEmpty) {
          final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);
          await pc.addCandidate(candidate);
        }
      } catch (e) {
        debugPrint('[WebRTC P2P] Erro ao adicionar ICE Candidate: $e');
      }
    }
  }

  void _handleIceFailure(String peerId, RTCPeerConnection pc) async {
    final attempts = (_iceRestartAttempts[peerId] ?? 0) + 1;
    _iceRestartAttempts[peerId] = attempts;

    if (attempts <= 3) {
      debugPrint('[WebRTC P2P] Tentando ICE Restart ($attempts/3) para $peerId...');
      _updateConnectionState(ScreenShareConnectionState.reconnecting);
      try {
        final offer = await pc.createOffer({'iceRestart': true});
        await pc.setLocalDescription(offer);
        _wsClient.sendEvent('WEBRTC_OFFER', {
          'session_id': _broadcastSession?.sessionId ?? '',
          'to_user_id': peerId,
          'sdp': offer.sdp,
        });
      } catch (e) {
        debugPrint('[WebRTC P2P] Falha no ICE Restart: $e');
      }
    } else {
      debugPrint('[WebRTC P2P] Limite máximo de ICE Restarts atingido para $peerId');
      _updateConnectionState(ScreenShareConnectionState.failed);
      _cleanupPeerConnection(peerId);
    }
  }

  String _mungeSDP(String sdp) {
    var munged = sdp;
    // Injetar H.264 High Profile profile-level-id=640034 e desativar throttling por CPU
    if (!munged.contains('profile-level-id=640034')) {
      munged = munged.replaceAll(
        'profile-level-id=42e01f',
        'profile-level-id=640034;packetization-mode=1;goog-cpu-overuse-detection=false',
      );
    }
    // Injetar parâmetros de alta qualidade para Opus Estéreo (256 kbps)
    if (munged.contains('opus/48000')) {
      munged = munged.replaceAll(
        'useinbandfec=1',
        'useinbandfec=1;stereo=1;sprop-stereo=1;maxaveragebitrate=256000;usedtx=0',
      );
    }
    return munged;
  }

  void _startStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      for (final entry in _peerConnections.entries) {
        try {
          final stats = await entry.value.getStats();
          double rtt = 0;
          int packetsLost = 0;
          double bitrateKbps = 0;
          int frameWidth = 0;
          int frameHeight = 0;
          int framesPerSecond = 0;
          const videoCodec = 'H.264 High Profile';

          for (final report in stats) {
            if (report.type == 'candidate-pair' && report.values['currentRoundTripTime'] != null) {
              rtt = (double.tryParse(report.values['currentRoundTripTime'].toString()) ?? 0) * 1000;
            }
            if (report.type == 'inbound-rtp' || report.type == 'outbound-rtp') {
              if (report.values['packetsLost'] != null) {
                packetsLost = int.tryParse(report.values['packetsLost'].toString()) ?? 0;
              }
              if (report.values['frameWidth'] != null) {
                frameWidth = int.tryParse(report.values['frameWidth'].toString()) ?? 0;
              }
              if (report.values['frameHeight'] != null) {
                frameHeight = int.tryParse(report.values['frameHeight'].toString()) ?? 0;
              }
              if (report.values['framesPerSecond'] != null) {
                framesPerSecond = int.tryParse(report.values['framesPerSecond'].toString()) ?? 0;
              }
              if (report.values['bytesReceived'] != null || report.values['bytesSent'] != null) {
                final bytes = double.tryParse((report.values['bytesReceived'] ?? report.values['bytesSent']).toString()) ?? 0;
                bitrateKbps = (bytes * 8) / 2000;
              }
            }
          }
          _statsController.add({
            'peer_id': entry.key,
            'rtt_ms': rtt,
            'packets_lost': packetsLost,
            'bitrate_kbps': bitrateKbps,
            'width': frameWidth > 0 ? frameWidth : 1920,
            'height': frameHeight > 0 ? frameHeight : 1080,
            'fps': framesPerSecond > 0 ? framesPerSecond : 60,
            'codec': videoCodec,
          });
        } catch (_) {}
      }
    });
  }

  void _handleRemoteSessionStopped(String sessionId) {
    final session = _viewerSessions.remove(sessionId);
    if (session != null) {
      _cleanupPeerConnection(session.broadcasterId);
    }
    if (_activeRemoteShare?.sessionId == sessionId) {
      _activeRemoteShare = null;
      _remoteStreamController.add(null);
    }
    if (_broadcastSession == null && _viewerSessions.isEmpty) {
      _updateConnectionState(ScreenShareConnectionState.closed);
    }
  }

  void _cleanupPeerConnection(String peerId) {
    final pc = _peerConnections.remove(peerId);
    pc?.close();
    pc?.dispose();
    _iceRestartAttempts.remove(peerId);
    _makingOffer.remove(peerId);
    _ignoreOffer.remove(peerId);
  }

  Future<void> _cleanupAll() async {
    _statsTimer?.cancel();
    _statsTimer = null;

    for (final peerId in _peerConnections.keys.toList()) {
      _cleanupPeerConnection(peerId);
    }
    _peerConnections.clear();

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
    }

    _activeRemoteShare = null;
    _remoteStreamController.add(null);
    _broadcastSession = null;
    _viewerSessions.clear();
  }

  @override
  void dispose() {
    _cleanupAll();
    _wsSubscription?.cancel();
    _remoteStreamController.close();
    _connectionStateController.close();
    _statsController.close();
  }
}
