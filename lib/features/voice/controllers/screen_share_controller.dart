import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/voice/services/p2p_webrtc_screen_transport.dart';
import 'package:projectnbx/features/voice/services/screen_capture_source.dart';
import 'package:projectnbx/features/voice/services/screen_share_transport.dart';

final screenCaptureSourceProvider = Provider<ScreenCaptureSource>((ref) {
  return DesktopScreenCaptureSource();
});

final screenShareTransportProvider = Provider<ScreenShareTransport>((ref) {
  final wsClient = ref.watch(websocketClientProvider);
  final apiClient = ref.watch(apiClientProvider);
  final transport = P2PWebRTCScreenTransport(
    wsClient: wsClient,
    apiClient: apiClient,
  );
  ref.onDispose(() {
    transport.dispose();
  });
  return transport;
});

class ScreenShareState {
  final bool isSharing;
  final bool isViewing;
  final bool isLoadingSources;
  final List<ScreenSource> availableSources;
  final ScreenSource? selectedSource;
  final ScreenQualityProfile selectedProfile;
  final ScreenShareSession? currentSession;
  final RemoteScreenShare? remoteShare;
  final ScreenShareConnectionState connectionState;
  final Map<String, dynamic> stats;
  final String? errorMessage;

  const ScreenShareState({
    this.isSharing = false,
    this.isViewing = false,
    this.isLoadingSources = false,
    this.availableSources = const [],
    this.selectedSource,
    this.selectedProfile = ScreenQualityProfile.medium,
    this.currentSession,
    this.remoteShare,
    this.connectionState = ScreenShareConnectionState.idle,
    this.stats = const {},
    this.errorMessage,
  });

  ScreenShareState copyWith({
    bool? isSharing,
    bool? isViewing,
    bool? isLoadingSources,
    List<ScreenSource>? availableSources,
    ScreenSource? selectedSource,
    ScreenQualityProfile? selectedProfile,
    ScreenShareSession? currentSession,
    RemoteScreenShare? remoteShare,
    ScreenShareConnectionState? connectionState,
    Map<String, dynamic>? stats,
    String? errorMessage,
    bool clearSelectedSource = false,
    bool clearRemoteShare = false,
    bool clearError = false,
  }) {
    return ScreenShareState(
      isSharing: isSharing ?? this.isSharing,
      isViewing: isViewing ?? this.isViewing,
      isLoadingSources: isLoadingSources ?? this.isLoadingSources,
      availableSources: availableSources ?? this.availableSources,
      selectedSource: clearSelectedSource ? null : (selectedSource ?? this.selectedSource),
      selectedProfile: selectedProfile ?? this.selectedProfile,
      currentSession: currentSession ?? this.currentSession,
      remoteShare: clearRemoteShare ? null : (remoteShare ?? this.remoteShare),
      connectionState: connectionState ?? this.connectionState,
      stats: stats ?? this.stats,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ScreenShareController extends StateNotifier<ScreenShareState> {
  final ScreenCaptureSource _captureSource;
  final ScreenShareTransport _transport;
  final WebSocketClient _wsClient;

  StreamSubscription<RemoteScreenShare?>? _remoteStreamSub;
  StreamSubscription<ScreenShareConnectionState>? _connStateSub;
  StreamSubscription<Map<String, dynamic>>? _statsSub;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  ScreenShareController({
    required ScreenCaptureSource captureSource,
    required ScreenShareTransport transport,
    required WebSocketClient wsClient,
  })  : _captureSource = captureSource,
        _transport = transport,
        _wsClient = wsClient,
        super(const ScreenShareState()) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _remoteStreamSub = _transport.remoteStreamStream.listen((remoteShare) {
      if (remoteShare != null) {
        state = state.copyWith(
          isViewing: true,
          remoteShare: remoteShare,
          connectionState: ScreenShareConnectionState.connected,
        );
      } else {
        state = state.copyWith(
          isViewing: false,
          clearRemoteShare: true,
        );
      }
    });

    _connStateSub = _transport.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
      if (connState == ScreenShareConnectionState.closed ||
          connState == ScreenShareConnectionState.failed) {
        if (state.isSharing) {
          state = state.copyWith(isSharing: false);
        }
        if (state.isViewing) {
          state = state.copyWith(isViewing: false, clearRemoteShare: true);
        }
      }
    });

    _statsSub = _transport.statsStream.listen((stats) {
      state = state.copyWith(stats: stats);
    });

    _wsSub = _wsClient.eventStream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'SCREEN_SHARE_AVAILABLE') {
        // Notificação de tela disponível no canal
        final payload = event['payload'];
        if (payload is Map) {
          final sessId = payload['session_id'] as String?;
          final bId = payload['broadcaster_id'] as String?;
          if (sessId != null && bId != null && !state.isSharing && !state.isViewing) {
            // Auto-join ou disponibilidade
          }
        }
      } else if (type == 'SCREEN_SHARE_ERROR') {
        final payload = event['payload'];
        String msg = 'Erro no compartilhamento de tela';
        if (payload is Map && payload['message'] != null) {
          msg = payload['message'].toString();
        }
        state = state.copyWith(errorMessage: msg);
      }
    });
  }

  Future<void> loadSources() async {
    state = state.copyWith(isLoadingSources: true, clearError: true);
    try {
      final sources = await _captureSource.getSources(includeWindows: true);
      state = state.copyWith(
        availableSources: sources,
        selectedSource: sources.isNotEmpty ? sources.first : null,
        isLoadingSources: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSources: false,
        errorMessage: 'Falha ao listar telas e janelas disponíveis: $e',
      );
    }
  }

  void selectSource(ScreenSource source) {
    state = state.copyWith(selectedSource: source);
  }

  void selectProfile(ScreenQualityProfile profile) {
    state = state.copyWith(selectedProfile: profile);
  }

  Future<bool> startScreenShare(String channelId) async {
    final source = state.selectedSource;
    if (source == null) {
      state = state.copyWith(errorMessage: 'Nenhuma fonte de tela selecionada');
      return false;
    }

    try {
      state = state.copyWith(
        connectionState: ScreenShareConnectionState.connecting,
        clearError: true,
      );

      final mediaStream = await _captureSource.capture(source, state.selectedProfile);
      final session = await _transport.startBroadcast(
        channelId: channelId,
        stream: mediaStream,
        profile: state.selectedProfile,
      );

      state = state.copyWith(
        isSharing: true,
        currentSession: session,
        connectionState: ScreenShareConnectionState.connected,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSharing: false,
        connectionState: ScreenShareConnectionState.failed,
        errorMessage: 'Erro ao iniciar transmissão: $e',
      );
      return false;
    }
  }

  Future<void> stopScreenShare() async {
    try {
      await _transport.stopBroadcast();
    } catch (_) {}
    state = state.copyWith(
      isSharing: false,
      connectionState: ScreenShareConnectionState.idle,
    );
  }

  Future<void> joinScreenShare(String sessionId, String broadcasterId) async {
    try {
      state = state.copyWith(
        isViewing: true,
        connectionState: ScreenShareConnectionState.connecting,
        clearError: true,
      );
      await _transport.connectTo(
        sessionId: sessionId,
        broadcasterId: broadcasterId,
      );
    } catch (e) {
      state = state.copyWith(
        isViewing: false,
        connectionState: ScreenShareConnectionState.failed,
        errorMessage: 'Erro ao assistir transmissão: $e',
      );
    }
  }

  Future<void> leaveScreenShare() async {
    final sessId = state.remoteShare?.sessionId ?? state.currentSession?.sessionId ?? '';
    try {
      await _transport.disconnectFrom(sessionId: sessId);
    } catch (_) {}
    state = state.copyWith(
      isViewing: false,
      clearRemoteShare: true,
      connectionState: ScreenShareConnectionState.idle,
    );
  }

  @override
  void dispose() {
    _remoteStreamSub?.cancel();
    _connStateSub?.cancel();
    _statsSub?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }
}

final screenShareControllerProvider =
    StateNotifierProvider<ScreenShareController, ScreenShareState>((ref) {
  final captureSource = ref.watch(screenCaptureSourceProvider);
  final transport = ref.watch(screenShareTransportProvider);
  final wsClient = ref.watch(websocketClientProvider);

  return ScreenShareController(
    captureSource: captureSource,
    transport: transport,
    wsClient: wsClient,
  );
});
