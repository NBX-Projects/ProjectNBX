import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart' hide ChatMessage;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/widgets/channel_chat_view.dart';
import 'package:projectnbx/features/chat/widgets/floating_chat_hud.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/models/server_workspace_enums.dart';
import 'package:projectnbx/features/servers/widgets/invite_member_dialog.dart';
import 'package:projectnbx/features/servers/widgets/server_home_view.dart';
import 'package:projectnbx/features/servers/widgets/server_right_sidebar.dart';
import 'package:projectnbx/features/servers/widgets/server_top_nav.dart';
import 'package:projectnbx/features/voice/controllers/audio_devices_controller.dart';
import 'package:projectnbx/features/voice/controllers/audio_settings_controller.dart';
import 'package:projectnbx/features/voice/controllers/screen_share_controller.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';
import 'package:projectnbx/features/voice/services/desktop_hardware_service.dart';
import 'package:projectnbx/features/voice/widgets/immersive_stream_player.dart';
import 'package:projectnbx/features/voice/widgets/screen_share_dialog.dart';
import 'package:projectnbx/features/voice/widgets/stream_bottom_control_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:projectnbx/features/servers/models/server_workspace_enums.dart';

class ServerWorkspaceView extends ConsumerStatefulWidget {
  final ServerModel server;
  final VoidCallback onBackToHome;

  const ServerWorkspaceView({
    super.key,
    required this.server,
    required this.onBackToHome,
  });

  @override
  ConsumerState<ServerWorkspaceView> createState() =>
      _ServerWorkspaceViewState();
}

class _ServerWorkspaceViewState extends ConsumerState<ServerWorkspaceView> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editMessageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final Map<String, List<ChatMessage>> _channelMessages = {};

  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  String? _editingMessageId;
  ServerViewMode _viewMode = ServerViewMode.home;
  ChannelModel? _activeChannel;

  int _selectedBannerPreset = 0;
  Color _selectedAccentColor = const Color(0xFFF5CBA7);
  bool _isCustomizingBanner = false;

  bool _isRightSidebarVisible = true;
  bool _isInVoice = false;
  bool _isConnectingLiveKit = false;
  bool _isLiveKitConnected = false;
  String? _connectedVoiceChannelId;
  Room? _liveKitRoom;
  Timer? _noiseGateReleaseTimer;
  bool _isGateOpen = true;

  late final String _clientSessionId =
      'sess_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
  final Map<String, Map<String, VoiceParticipantInfo>> _voiceParticipants = {};
  VoiceParticipantInfo? _watchingRemoteStream;

  VoiceParticipantInfo? get _activeBroadcaster {
    if (_activeChannel == null) return null;
    final map = _voiceParticipants[_activeChannel!.id];
    if (map == null) return null;
    final currentUserId = ref.read(authControllerProvider).user?.id;
    for (final p in map.values) {
      if (p.isInVoice && p.isTransmitting && p.userId != currentUserId && p.sessionId != _clientSessionId) {
        return p;
      }
    }
    return null;
  }

  void _processNoiseGate(double audioLevel) {
    if (!mounted || _liveKitRoom == null) return;
    final audioSettings = ref.read(audioSettingsProvider);
    final voiceState = ref.read(voiceStateProvider);

    // If auto noise gate is on or mic is muted/deafened, keep standard transmission open
    if (audioSettings.autoNoiseGate || voiceState.isMicMuted || voiceState.isDeafened) {
      if (!_isGateOpen) {
        _setLocalAudioTrackEnabled(true);
        _isGateOpen = true;
      }
      return;
    }

    final threshold = audioSettings.noiseGateThreshold;

    if (audioLevel >= threshold) {
      // Sound reached voice threshold - open gate immediately
      _noiseGateReleaseTimer?.cancel();
      _noiseGateReleaseTimer = null;
      if (!_isGateOpen) {
        _setLocalAudioTrackEnabled(true);
        _isGateOpen = true;
      }
    } else if (_isGateOpen && _noiseGateReleaseTimer == null) {
      // Sound fell below threshold (typing, breathing, room noise) - start release countdown
      _noiseGateReleaseTimer = Timer(
        Duration(milliseconds: audioSettings.noiseGateReleaseMs),
        () {
          if (!mounted) return;
          _setLocalAudioTrackEnabled(false);
          _isGateOpen = false;
          _noiseGateReleaseTimer = null;
        },
      );
    }
  }

  void _setLocalAudioTrackEnabled(bool enabled) {
    final pubs = _liveKitRoom?.localParticipant?.audioTrackPublications;
    if (pubs == null) return;
    for (final pub in pubs) {
      final track = pub.track;
      if (track is LocalAudioTrack) {
        track.mediaStreamTrack.enabled = enabled;
      }
    }
  }

    AudioCaptureOptions _buildAudioCaptureOptions() {
    final audioSettings = ref.read(audioSettingsProvider);
    final selectedInputId = ref.read(audioDevicesProvider).selectedInputDeviceId;
    final deviceId = (selectedInputId == null || selectedInputId == 'default')
        ? null
        : selectedInputId;
    return audioSettings.toAudioCaptureOptions(deviceId: deviceId);
  }

  Future<void> _updateLiveKitAudioProcessing(AudioSettings settings) async {
    if (_liveKitRoom == null) return;
    try {
      final pubs = _liveKitRoom?.localParticipant?.audioTrackPublications;
      if (pubs == null) return;
      for (final pub in pubs) {
        final track = pub.track;
        if (track is LocalAudioTrack) {
          try {
            // ignore: experimental_member_use
            await track.setAudioProcessingOptions(settings.toAudioProcessingOptions());
            debugPrint('[LiveKit] Opções de áudio atualizadas dinamicamente');
          } catch (_) {
            track.currentOptions = track.currentOptions.copyWith(
              echoCancellation: settings.echoCancellation,
              noiseSuppression: settings.noiseSuppression,
              autoGainControl: settings.compressorEnabled,
              highPassFilter: settings.highPassFilter,
              typingNoiseDetection: settings.typingNoiseDetection,
              voiceIsolation: settings.noiseSuppression,
            );
            await track.restartTrack();
            debugPrint('[LiveKit] Track de áudio reiniciado com novo processamento');
          }
        }
      }
    } catch (e) {
      debugPrint('[LiveKit] Erro ao atualizar processamento de áudio dinamicamente: $e');
    }
  }

  Future<void> _updateLiveKitAudioDevice(String? deviceId) async {
    if (_liveKitRoom == null || deviceId == null) return;
    try {
      final pubs = _liveKitRoom?.localParticipant?.audioTrackPublications;
      if (pubs == null) return;
      var targetId = deviceId == 'default' ? '' : deviceId;
      if (targetId.startsWith(r'SWD\MMDEVAPI\')) {
        targetId = targetId.replaceFirst(r'SWD\MMDEVAPI\', '');
      }

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        try {
          await rtc.Helper.selectAudioInput(targetId);
          debugPrint('[LiveKit] selectAudioInput configurado para: $targetId');
        } catch (e) {
          debugPrint('[LiveKit] selectAudioInput falhou ou não suportado: $e');
        }
      }

      for (final pub in pubs) {
        final track = pub.track;
        if (track is LocalAudioTrack) {
          await track.setDeviceId(targetId);
          try {
            await track.restartTrack();
          } catch (e) {
            debugPrint('[LiveKit] Erro ao reiniciar track após troca de microfone: $e');
          }
          debugPrint('[LiveKit] Dispositivo de microfone atualizado: $targetId');
        }
      }
    } catch (e) {
      debugPrint('[LiveKit] Erro ao trocar dispositivo de áudio: $e');
    }
  }

  Future<void> _updateLiveKitAudioOutputDevice(String? deviceId) async {
    if (deviceId == null) return;
    try {
      var targetId = deviceId == 'default' ? '' : deviceId;
      if (targetId.startsWith(r'SWD\MMDEVAPI\')) {
        targetId = targetId.replaceFirst(r'SWD\MMDEVAPI\', '');
      }
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        try {
          await rtc.Helper.selectAudioOutput(targetId);
          debugPrint('[LiveKit] selectAudioOutput configurado para: $targetId');
        } catch (e) {
          debugPrint('[LiveKit] selectAudioOutput falhou ou não suportado: $e');
        }
      }
    } catch (e) {
      debugPrint('[LiveKit] Erro ao trocar dispositivo de saída de áudio: $e');
    }
  }

  Future<void> _connectToLiveKitVoice(String channelId) async {
    try {
      if (mounted) {
        setState(() {
          _isInVoice = true;
          _connectedVoiceChannelId = channelId;
          _isConnectingLiveKit = true;
          _isLiveKitConnected = false;
        });
      }
      await _disconnectFromLiveKitVoice();
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getVoiceToken(channelId);
      final token = (res['token'] as String?) ?? '';
      if (token.isEmpty) {
        if (mounted) {
          setState(() {
            _isInVoice = false;
            _connectedVoiceChannelId = null;
            _isConnectingLiveKit = false;
            _isLiveKitConnected = false;
          });
        }
        return;
      }
      const defaultLiveKitUrl = AppConfig.livekitUrl;
      var serverUrl = (res['server_url'] as String?) ?? defaultLiveKitUrl;
      if (serverUrl.isEmpty) {
        serverUrl = defaultLiveKitUrl;
      }

      // Garante o alinhamento de host e portas do LiveKit com o ambiente configurado
      try {
        final apiUri = Uri.parse(ApiClient.baseUrl);
        final liveKitUri = Uri.parse(serverUrl);
        if (liveKitUri.host == 'localhost' ||
            liveKitUri.host == '127.0.0.1' ||
            liveKitUri.host == 'livekit') {
          if (AppConfig.isProd) {
            if (AppConfig.livekitUrl.isNotEmpty &&
                !AppConfig.livekitUrl.contains('localhost') &&
                !AppConfig.livekitUrl.contains('127.0.0.1')) {
              serverUrl = AppConfig.livekitUrl;
            } else {
              // Fallback automático para o proxy reverso do backend Go (/api/livekit)
              final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
              final portStr = apiUri.hasPort &&
                      apiUri.port != 80 &&
                      apiUri.port != 443
                  ? ':${apiUri.port}'
                  : '';
              serverUrl = '$wsScheme://${apiUri.host}$portStr/api/livekit';
            }
          } else {
            final effectivePort = liveKitUri.hasPort ? liveKitUri.port : 7880;
            serverUrl = liveKitUri
                .replace(host: apiUri.host, port: effectivePort)
                .toString();
          }
        }
      } catch (_) {}

      final captureOptions = _buildAudioCaptureOptions();
      final room = Room(
        roomOptions: RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioCaptureOptions: captureOptions,
          defaultAudioPublishOptions: const AudioPublishOptions(dtx: true),
        ),
      );
      _liveKitRoom = room;

      // Escuta os eventos oficiais do LiveKit para sincronizar os participantes da call
      room.events.listen((event) {
        if (event is ParticipantConnectedEvent) {
          _syncLiveKitParticipant(event.participant, channelId, true);
        } else if (event is ParticipantDisconnectedEvent) {
          _syncLiveKitParticipant(event.participant, channelId, false);
        } else if (event is TrackSubscribedEvent) {
          final isDeafened = ref.read(voiceStateProvider).isDeafened;
          if (isDeafened && event.track is RemoteAudioTrack) {
            event.track.disable();
            event.track.mediaStreamTrack.enabled = false;
          }
          setState(() {});
        } else if (event is TrackMutedEvent) {
          final uid = event.participant.identity;
          if (uid.isNotEmpty && _voiceParticipants[channelId]?[uid] != null) {
            _voiceParticipants[channelId]![uid] =
                _voiceParticipants[channelId]![uid]!.copyWith(isMuted: true);
          }
          setState(() {});
        } else if (event is TrackUnmutedEvent) {
          final uid = event.participant.identity;
          if (uid.isNotEmpty && _voiceParticipants[channelId]?[uid] != null) {
            _voiceParticipants[channelId]![uid] =
                _voiceParticipants[channelId]![uid]!.copyWith(isMuted: false);
          }
          setState(() {});
        } else if (event is ActiveSpeakersChangedEvent) {
          final localSid = room.localParticipant?.sid;
          for (final speaker in event.speakers) {
            if (speaker.sid == localSid) {
              _processNoiseGate(speaker.audioLevel);
              break;
            }
          }
        }
      });

      await room.connect(
        serverUrl,
        token,
      );
      final currentVoiceState = ref.read(voiceStateProvider);
      final shouldMuteMic = currentVoiceState.isMicMuted || currentVoiceState.isDeafened;
      try {
        await room.localParticipant?.setMicrophoneEnabled(
          !shouldMuteMic,
          audioCaptureOptions: captureOptions,
        );
      } catch (_) {}

      // Se já estiver ensurdecido ao conectar, muta o áudio remoto imediatamente
      if (currentVoiceState.isDeafened) {
        for (final remote in room.remoteParticipants.values) {
          for (final pub in remote.audioTrackPublications) {
            final t = pub.track;
            if (t != null) {
              await t.disable();
              t.mediaStreamTrack.enabled = false;
            }
          }
        }
      }

      // Sincroniza participantes confirmados pelo LiveKit
      final local = room.localParticipant;
      if (local != null) {
        _syncLiveKitParticipant(local, channelId, true);
      }
      for (final remote in room.remoteParticipants.values) {
        _syncLiveKitParticipant(remote, channelId, true);
      }

      if (mounted) {
        ref.read(voiceStateProvider.notifier).connectVoice(widget.server.id, channelId);
        setState(() {
          _isInVoice = true;
          _connectedVoiceChannelId = channelId;
          _isConnectingLiveKit = false;
          _isLiveKitConnected = true;
          final uid = ref.read(authControllerProvider).user?.id ?? '';
          if (uid.isNotEmpty && _voiceParticipants[channelId]?[uid] != null) {
            _voiceParticipants[channelId]![uid] = _voiceParticipants[channelId]![uid]!.copyWith(
              isConnecting: false,
            );
          }
        });
        _broadcastVoiceState(isInVoice: true, channelId: channelId, isConnecting: false);
      }
      debugPrint('[LiveKit] Conectado na sala de voz com sucesso: $channelId');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInVoice = false;
          _connectedVoiceChannelId = null;
          _isConnectingLiveKit = false;
          _isLiveKitConnected = false;
        });
      }
      debugPrint('[LiveKit] Erro ao conectar na sala de voz: $e');
    }
  }

  Future<void> _disconnectFromLiveKitVoice() async {
    if (_liveKitRoom != null) {
      try {
        _noiseGateReleaseTimer?.cancel();
        _noiseGateReleaseTimer = null;
        _isGateOpen = true;
        await _liveKitRoom?.disconnect();
        await _liveKitRoom?.dispose();
        final chId = _connectedVoiceChannelId ?? _activeChannel?.id;
        if (chId != null && mounted) {
          final currentUserId = ref.read(authControllerProvider).user?.id;
          _voiceParticipants[chId]?.removeWhere((k, v) => v.userId == currentUserId || v.sessionId == _clientSessionId);
        }
      } catch (e) {
        debugPrint('[LiveKit] Erro ao desconectar da sala: $e');
      }
      _liveKitRoom = null;
    }
  }

  void _syncLiveKitParticipant(Participant participant, String channelId, bool joined) {
    if (!mounted) return;
    final uid = participant.identity;
    if (uid.isEmpty) return;
    final uname = participant.name.isNotEmpty ? participant.name : uid;
    setState(() {
      final chMap = _voiceParticipants.putIfAbsent(channelId, () => {});
      if (joined) {
        final existing = chMap[uid];
        chMap[uid] = VoiceParticipantInfo(
          sessionId: participant.sid.isNotEmpty ? participant.sid : (existing?.sessionId ?? uid),
          userId: uid,
          username: uname,
          serverId: widget.server.id,
          channelId: channelId,
          device: existing?.device ?? 'desktop',
          isInVoice: true,
          isConnecting: false,
          isTransmitting: existing?.isTransmitting ?? false,
          streamTitle: existing?.streamTitle,
          previewType: existing?.previewType,
          thumbnail: existing?.thumbnail,
          isMuted: participant.isMuted || (existing?.isMuted ?? false),
          isDeafened: existing?.isDeafened ?? false,
          isSpeaking: participant.isSpeaking,
          updatedAt: DateTime.now(),
        );
      } else {
        chMap.remove(uid);
        chMap.removeWhere((k, v) => v.userId == uid || (participant.sid.isNotEmpty && v.sessionId == participant.sid));
      }
    });
  }

  // Real stream / screen share transmission state
  bool _isTransmitting = false;
  ScreenShareConfig? _activeScreenShareConfig;
  LocalVideoTrack? _localScreenShareTrack;
  Timer? _streamRefreshTimer;
  bool _isCapturingStreamFrame = false;
  double _streamVolume = 0.75;
  bool _isChatVisible = false;
  bool _isFullscreen = false;

  List<Map<String, dynamic>> _serverMembers = [];

  @override
  void initState() {
    super.initState();
    _selectedBannerPreset = widget.server.bannerPreset.clamp(
      0,
      AppColors.bannerPresets.length - 1,
    );
    _selectedAccentColor = Color(widget.server.accentColor);
    if (widget.server.channels.isNotEmpty) {
      _activeChannel = widget.server.channels.first;
    }
    _loadPersistedMessages();
    _loadServerMembers();
    _initWebSocketAndSync();
  }

  Future<void> _handleMicToggle() async {
    final nextState = ref.read(voiceStateProvider);
    await _applyMicState(nextState.isMicMuted);
  }

  Future<void> _handleDeafenToggle() async {
    final nextState = ref.read(voiceStateProvider);
    await _applyMicState(nextState.isMicMuted);
    await _applyDeafenState(nextState.isDeafened);
  }

  Future<void> _applyMicState(bool isMuted) async {
    final isDeafened = ref.read(voiceStateProvider).isDeafened;
    final shouldMute = isMuted || isDeafened;
    try {
      final captureOptions = _buildAudioCaptureOptions();
      await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(
        !shouldMute,
        audioCaptureOptions: captureOptions,
      );
      debugPrint('[LiveKit] Microfone alterado: isMuted=$isMuted, shouldMute=$shouldMute');
    } catch (e) {
      debugPrint('[LiveKit] Erro ao alterar microfone: $e');
    }
    final uid = ref.read(authControllerProvider).user?.id ?? '';
    final cid = _connectedVoiceChannelId ?? _activeChannel?.id;
    if (cid != null && uid.isNotEmpty && mounted) {
      setState(() {
        final chMap = _voiceParticipants[cid];
        if (chMap != null && chMap[uid] != null) {
          chMap[uid] = chMap[uid]!.copyWith(isMuted: isMuted);
        }
      });
    }
    _broadcastVoiceState(
      isInVoice: _isInVoice,
      isMuted: isMuted,
      isDeafened: isDeafened,
    );
  }

  Future<void> _applyDeafenState(bool isDeafened) async {
    try {
      if (_liveKitRoom != null) {
        for (final p in _liveKitRoom!.remoteParticipants.values) {
          for (final pub in p.audioTrackPublications) {
            final t = pub.track;
            if (t != null) {
              if (isDeafened) {
                await t.disable();
              } else {
                await t.enable();
              }
              t.mediaStreamTrack.enabled = !isDeafened;
            }
          }
        }
        final voiceState = ref.read(voiceStateProvider);
        final shouldMuteMic = isDeafened || voiceState.isMicMuted;
        final captureOptions = _buildAudioCaptureOptions();
        await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(
          !shouldMuteMic,
          audioCaptureOptions: captureOptions,
        );
      }
      debugPrint('[LiveKit] Áudio alterado (deafen): isDeafened=$isDeafened');
    } catch (e) {
      debugPrint('[LiveKit] Erro ao alterar áudio (deafen): $e');
    }
    final uid = ref.read(authControllerProvider).user?.id ?? '';
    final cid = _connectedVoiceChannelId ?? _activeChannel?.id;
    if (cid != null && uid.isNotEmpty && mounted) {
      setState(() {
        final chMap = _voiceParticipants[cid];
        if (chMap != null && chMap[uid] != null) {
          chMap[uid] = chMap[uid]!.copyWith(isDeafened: isDeafened);
        }
      });
    }
    final voiceState = ref.read(voiceStateProvider);
    _broadcastVoiceState(
      isInVoice: _isInVoice,
      isMuted: voiceState.isMicMuted,
      isDeafened: isDeafened,
    );
  }

  void _broadcastVoiceState({
    required bool isInVoice,
    bool? isTransmitting,
    bool? isConnecting,
    String? streamTitle,
    String? previewType,
    String? thumbnail,
    String? channelId,
    bool? isMuted,
    bool? isDeafened,
  }) {
    final user = ref.read(authControllerProvider).user;
    final cid =
        channelId ?? _connectedVoiceChannelId ?? _activeChannel?.id ?? '';
    final uname = (user?.username ?? '').isNotEmpty ? user!.username : 'Você';
    final uid = user?.id ?? 'user_${_clientSessionId.hashCode.abs()}';
    final transmitting = isTransmitting ?? _isTransmitting;
    final connecting = isConnecting ?? _isConnectingLiveKit;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final deviceStr = isMobile ? 'mobile' : 'desktop';
    final voiceState = ref.read(voiceStateProvider);
    final muted = isMuted ?? voiceState.isMicMuted;
    final deafened = isDeafened ?? voiceState.isDeafened;

    final payload = <String, dynamic>{
      'session_id': _clientSessionId,
      'user_id': uid,
      'username': uname,
      'server_id': widget.server.id,
      'channel_id': cid,
      'device': deviceStr,
      'is_in_voice': isInVoice,
      if (connecting) 'is_connecting': true,
      'is_transmitting': transmitting,
      if (streamTitle != null || _activeScreenShareConfig?.title != null)
        'stream_title': streamTitle ?? _activeScreenShareConfig?.title,
      if (previewType != null || _activeScreenShareConfig?.previewType != null)
        'preview_type': previewType ?? _activeScreenShareConfig?.previewType,
      if (thumbnail != null || _activeScreenShareConfig?.thumbnail != null)
        'thumbnail': thumbnail ?? _activeScreenShareConfig?.thumbnail,
      'is_muted': muted,
      'is_deafened': deafened,
    };

    if (cid.isNotEmpty) {
      setState(() {
        final chMap = _voiceParticipants.putIfAbsent(cid, () => {});
        if (isInVoice) {
          chMap[uid.isNotEmpty ? uid : _clientSessionId] = VoiceParticipantInfo.fromJson(payload);
        } else {
          chMap.remove(uid);
          chMap.remove(_clientSessionId);
        }
      });
    }

    try {
      ref.read(websocketClientProvider).sendEvent(
            'VOICE_STATE',
            payload,
            channelId: cid,
            serverId: widget.server.id,
          );
    } catch (e) {
      debugPrint('[WebSocket] Erro ao enviar VOICE_STATE: $e');
    }
  }

  void _initWebSocketAndSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wsClient = ref.read(websocketClientProvider);
      wsClient.connect(serverId: widget.server.id);

      _wsSubscription?.cancel();
      _wsSubscription = wsClient.eventStream.listen(_handleWebSocketEvent);

      try {
        wsClient.sendEvent(
          'VOICE_SYNC',
          <String, dynamic>{},
          serverId: widget.server.id,
        );
      } catch (_) {}
    });
  }

  void _handleWebSocketEvent(Map<String, dynamic> event) {
    if (!mounted) return;

    final type = event['type']?.toString();
    if (type == null) return;

    final eventServerId = event['server_id']?.toString();
    if (eventServerId != null &&
        eventServerId.isNotEmpty &&
        eventServerId != widget.server.id) {
      return;
    }

    final dynamic rawPayload = event['payload'];
    Map<String, dynamic> payload = {};
    if (rawPayload is Map) {
      payload = Map<String, dynamic>.from(rawPayload);
    } else if (rawPayload is String) {
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    if (type == 'VOICE_STATE') {
      final p = VoiceParticipantInfo.fromJson(payload);
      final chId = p.channelId.isNotEmpty
          ? p.channelId
          : (event['channel_id'] ?? _activeChannel?.id ?? '').toString();
      if (chId.isNotEmpty) {
        setState(() {
          final chMap = _voiceParticipants.putIfAbsent(chId, () => {});
          if (p.isInVoice) {
            chMap.removeWhere((k, v) => v.userId == p.userId || v.sessionId == p.sessionId);
            chMap[p.userId.isNotEmpty ? p.userId : p.key] = p;
            if (_watchingRemoteStream?.sessionId == p.sessionId ||
                _watchingRemoteStream?.userId == p.userId) {
              _watchingRemoteStream = p;
            }
          } else {
            chMap.removeWhere((k, v) => v.userId == p.userId || v.sessionId == p.sessionId);
            if (_watchingRemoteStream?.sessionId == p.sessionId ||
                _watchingRemoteStream?.userId == p.userId) {
              _watchingRemoteStream = null;
            }
          }
        });
      }
      return;
    } else if (type == 'VOICE_SYNC') {
      List<dynamic> list = [];
      if (rawPayload is List) {
        list = rawPayload;
      } else if (payload['states'] is List) {
        list = payload['states'] as List<dynamic>;
      } else if (rawPayload is String) {
        try {
          final decoded = jsonDecode(rawPayload);
          if (decoded is List) list = decoded;
        } catch (_) {}
      }
      setState(() {
        for (final item in list) {
          if (item is Map) {
            final p = VoiceParticipantInfo.fromJson(Map<String, dynamic>.from(item));
            if (p.channelId.isNotEmpty && p.isInVoice) {
              final chMap = _voiceParticipants.putIfAbsent(p.channelId, () => {});
              chMap.removeWhere((k, v) => v.userId == p.userId || v.sessionId == p.sessionId);
              chMap[p.userId.isNotEmpty ? p.userId : p.key] = p;
            }
          }
        }
      });
      return;
    }

    final channelId = (event['channel_id'] ??
            payload['channel_id'] ??
            _activeChannel?.id)
        ?.toString();
    if (channelId == null || channelId.isEmpty) return;

    if (type == 'CHAT_MESSAGE') {
      final newMsg = ChatMessage.fromApi(payload, _selectedAccentColor);
      setState(() {
        final list = _channelMessages.putIfAbsent(channelId, () => []);
        final idx = list.indexWhere((m) => m.id == newMsg.id);
        if (idx != -1) {
          list[idx] = newMsg;
        } else {
          final tempIdx = list.indexWhere(
            (m) =>
                m.id.startsWith('msg_') &&
                m.content == newMsg.content,
          );
          if (tempIdx != -1) {
            list[tempIdx] = newMsg;
          } else {
            list.add(newMsg);
          }
        }
      });
      _saveChannelMessages(channelId);

      if (_activeChannel?.id == channelId || _activeChannel == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } else if (type == 'MESSAGE_UPDATE') {
      final msgId = payload['id']?.toString();
      final newContent = payload['content']?.toString() ?? '';
      if (msgId != null && msgId.isNotEmpty) {
        setState(() {
          final list = _channelMessages[channelId];
          if (list != null) {
            final idx = list.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              list[idx] = list[idx].copyWith(content: newContent, isEdited: true);
            }
          }
        });
        _saveChannelMessages(channelId);
      }
    } else if (type == 'MESSAGE_DELETE') {
      final msgId = payload['id']?.toString();
      if (msgId != null && msgId.isNotEmpty) {
        setState(() {
          final list = _channelMessages[channelId];
          if (list != null) {
            list.removeWhere((m) => m.id == msgId);
          }
        });
        _saveChannelMessages(channelId);
      }
    }
  }

  Future<void> _loadServerMembers() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final list = await apiClient.getServerMembers(widget.server.id);
      if (mounted) {
        setState(() {
          _serverMembers = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPersistedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'channel_messages_${widget.server.id}_';
      final keys = prefs.getKeys().where((k) => k.startsWith(prefix));
      final Map<String, List<ChatMessage>> loaded = {};

      for (final key in keys) {
        final chKey = key.substring(prefix.length);
        final rawJson = prefs.getString(key);
        if (rawJson != null && rawJson.isNotEmpty) {
          try {
            final list = (jsonDecode(rawJson) as List<dynamic>)
                .map(
                  (item) => ChatMessage.fromJson(item as Map<String, dynamic>),
                )
                .toList();
            loaded[chKey] = list;
          } catch (_) {}
        }
      }

      if (mounted && loaded.isNotEmpty) {
        setState(() {
          _channelMessages.addAll(loaded);
        });
      }

      // Fetch from API in background for current or first channel
      final apiClient = ref.read(apiClientProvider);
      final activeChId =
          _activeChannel?.id ??
          (widget.server.channels.isNotEmpty
              ? widget.server.channels.first.id
              : 'chn_geral');
      final apiMsgs = await apiClient.getMessages(widget.server.id, activeChId);
      if (mounted && apiMsgs.isNotEmpty) {
        final mapped = apiMsgs
            .map((m) => ChatMessage.fromApi(m, _selectedAccentColor))
            .toList();

        setState(() {
          _channelMessages[activeChId] = mapped;
        });
        await _saveChannelMessages(activeChId);
      }
    } catch (_) {}
  }

  Future<void> _saveChannelMessages(String channelKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final msgs = _channelMessages[channelKey] ?? [];
      final key = 'channel_messages_${widget.server.id}_$channelKey';
      final jsonStr = jsonEncode(msgs.map((m) => m.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(ServerWorkspaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id ||
        oldWidget.server.bannerPreset != widget.server.bannerPreset ||
        oldWidget.server.accentColor != widget.server.accentColor) {
      setState(() {
        _selectedBannerPreset = widget.server.bannerPreset.clamp(
          0,
          AppColors.bannerPresets.length - 1,
        );
        _selectedAccentColor = Color(widget.server.accentColor);
      });
      if (oldWidget.server.id != widget.server.id) {
        _loadPersistedMessages();
        _loadServerMembers();
        _initWebSocketAndSync();
      }
    }
  }

  @override
  void dispose() {
    _noiseGateReleaseTimer?.cancel();
    _noiseGateReleaseTimer = null;
    _streamRefreshTimer?.cancel();
    _localScreenShareTrack?.stop();
    _localScreenShareTrack?.dispose();
    _localScreenShareTrack = null;
    _wsSubscription?.cancel();
    _disconnectFromLiveKitVoice();
    _messageFocusNode.dispose();
    _messageController.dispose();
    _editMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String channelKey, String authorName) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _messageFocusNode.requestFocus();
      return;
    }

    final targetChannelId = _activeChannel?.id ?? channelKey;
    final tempId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
    final newMsg = ChatMessage(
      id: tempId,
      author: authorName,
      authorColor: _selectedAccentColor,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _channelMessages.putIfAbsent(targetChannelId, () => []).add(newMsg);
      _messageController.clear();
    });

    _messageFocusNode.requestFocus();

    await _saveChannelMessages(targetChannelId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    // Send via WebSocket in real-time
    final wsClient = ref.read(websocketClientProvider);
    wsClient.sendEvent(
      'CHAT_MESSAGE',
      {'content': text},
      channelId: targetChannelId,
      serverId: widget.server.id,
    );

    _messageFocusNode.requestFocus();
  }

  void _startEditingMessage(ChatMessage msg) {
    setState(() {
      _editingMessageId = msg.id;
      _editMessageController.text = msg.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _editMessageController.clear();
    });
  }

  Future<void> _saveEditedMessage(String channelKey) async {
    final text = _editMessageController.text.trim();
    if (text.isEmpty || _editingMessageId == null) {
      _cancelEditing();
      return;
    }

    final msgId = _editingMessageId!;
    setState(() {
      final list = _channelMessages[channelKey];
      if (list != null) {
        final index = list.indexWhere((m) => m.id == msgId);
        if (index != -1) {
          list[index] = list[index].copyWith(content: text, isEdited: true);
        }
      }
      _editingMessageId = null;
      _editMessageController.clear();
    });

    await _saveChannelMessages(channelKey);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateMessage(widget.server.id, channelKey, msgId, text);
    } catch (_) {}
  }

  Future<void> _deleteMessage(String channelKey, String messageId) async {
    setState(() {
      final list = _channelMessages[channelKey];
      if (list != null) {
        list.removeWhere((m) => m.id == messageId);
      }
      if (_editingMessageId == messageId) {
        _editingMessageId = null;
        _editMessageController.clear();
      }
    });

    await _saveChannelMessages(channelKey);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteMessage(widget.server.id, channelKey, messageId);
    } catch (_) {}
  }

  void _openHybridChannel(ChannelModel channel, {bool joinVoice = false}) {
    final shouldJoin = joinVoice || channel.type == ChannelType.voice;
    final prevChannelId = _connectedVoiceChannelId;
    if (shouldJoin && prevChannelId != null && prevChannelId != channel.id) {
      _disconnectFromLiveKitVoice();
      _broadcastVoiceState(isInVoice: false, channelId: prevChannelId);
    }
    final uid = ref.read(authControllerProvider).user?.id ?? '';
    final uname = ref.read(authControllerProvider).user?.username ?? 'Usuário';

    setState(() {
      _activeChannel = channel;
      _viewMode = ServerViewMode.channel;
      if (shouldJoin) {
        _isInVoice = true;
        _connectedVoiceChannelId = channel.id;
        _isConnectingLiveKit = true;
        _isLiveKitConnected = false;

        if (uid.isNotEmpty) {
          final chMap = _voiceParticipants.putIfAbsent(channel.id, () => {});
          chMap[uid] = VoiceParticipantInfo(
            sessionId: _clientSessionId,
            userId: uid,
            username: uname,
            serverId: widget.server.id,
            channelId: channel.id,
            isInVoice: true,
            isConnecting: true,
            updatedAt: DateTime.now(),
          );
        }
      }
    });

    if (shouldJoin) {
      _broadcastVoiceState(isInVoice: true, channelId: channel.id, isConnecting: true);
      _connectToLiveKitVoice(channel.id);
    }
    ref.read(serversControllerProvider.notifier).selectChannel(channel.id);
    _loadChannelFromApi(channel.id);
  }

  Future<void> _loadChannelFromApi(String channelId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final apiMsgs = await apiClient.getMessages(widget.server.id, channelId);
      if (mounted) {
        final mapped = apiMsgs
            .map((m) => ChatMessage.fromApi(m, _selectedAccentColor))
            .toList();

        setState(() {
          _channelMessages[channelId] = mapped;
        });
        await _saveChannelMessages(channelId);
      }
    } catch (_) {}
  }

  void _leaveVoice() {
    ref.read(voiceStateProvider.notifier).disconnectVoice();
    _streamRefreshTimer?.cancel();
    _localScreenShareTrack?.stop();
    _localScreenShareTrack?.dispose();
    _localScreenShareTrack = null;
    _disconnectFromLiveKitVoice();
    setState(() {
      _isInVoice = false;
      _isConnectingLiveKit = false;
      _isLiveKitConnected = false;
      _isTransmitting = false;
      _activeScreenShareConfig = null;
      _connectedVoiceChannelId = null;
      _isRightSidebarVisible = true;
      _viewMode = ServerViewMode.home;
      _watchingRemoteStream = null;
      final prevChannelId = _connectedVoiceChannelId ?? _activeChannel?.id;
      final uid = ref.read(authControllerProvider).user?.id ?? '';
      if (prevChannelId != null) {
        _voiceParticipants[prevChannelId]?.remove(uid);
        _voiceParticipants[prevChannelId]?.remove(_clientSessionId);
      }
    });
  }

  void _startLiveStreamBroadcaster(ScreenShareConfig config) {
    _streamRefreshTimer?.cancel();
    _streamRefreshTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (!mounted || !_isTransmitting) {
        _streamRefreshTimer?.cancel();
        return;
      }
      if (_isCapturingStreamFrame) return;
      _isCapturingStreamFrame = true;

      try {
        const hardwareService = DesktopHardwareService();
        // 1. Ultra-fast targeted frame capture
        String? newThumb = await hardwareService.captureSingleSource(
          type: config.type,
          sourceId: config.sourceId,
          title: config.title,
        );

        // 2. Fallback to all sources scan if single capture is empty
        if (newThumb == null || newThumb.isEmpty) {
          final all = await hardwareService.getAllSources();
          if (!mounted || !_isTransmitting) return;
          final list = config.type == 'screen' ? all.screens : all.windows;
          for (final item in list) {
            final title = item is RealScreenInfo ? item.title : (item as RealWindowInfo).title;
            final thumb = item is RealScreenInfo ? item.thumbnail : (item as RealWindowInfo).thumbnail;
            final itemId = item is RealScreenInfo ? item.id : (item as RealWindowInfo).id;
            if (title.toLowerCase().trim() == config.title.toLowerCase().trim() ||
                (config.sourceId != null && itemId == config.sourceId)) {
              newThumb = thumb;
              break;
            }
          }
        }

        if (newThumb != null && newThumb.isNotEmpty && mounted && _isTransmitting) {
          final hasChanged = newThumb != _activeScreenShareConfig?.thumbnail;
          if (hasChanged) {
            setState(() {
              _activeScreenShareConfig = ScreenShareConfig(
                title: config.title,
                type: config.type,
                resolution: config.resolution,
                fps: config.fps,
                shareAudio: config.shareAudio,
                previewType: config.previewType,
                thumbnail: newThumb,
                sourceId: config.sourceId,
              );
            });
          }
          _broadcastVoiceState(
            isInVoice: true,
            isTransmitting: true,
            streamTitle: config.title,
            previewType: config.previewType,
            thumbnail: newThumb,
            channelId: _activeChannel?.id,
          );
        }
      } catch (e) {
        debugPrint('[LiveStreamBroadcaster] Erro ao sincronizar frame: $e');
      } finally {
        _isCapturingStreamFrame = false;
      }
    });
  }

  Future<void> _toggleTransmission() async {
    final screenShareState = ref.read(screenShareControllerProvider);
    final screenShareCtrl = ref.read(screenShareControllerProvider.notifier);

    if (_isTransmitting || screenShareState.isSharing) {
      _streamRefreshTimer?.cancel();
      await screenShareCtrl.stopScreenShare();
      await _localScreenShareTrack?.stop();
      await _localScreenShareTrack?.dispose();
      _localScreenShareTrack = null;
      setState(() {
        _isTransmitting = false;
        _activeScreenShareConfig = null;
        _isRightSidebarVisible = true;
      });
      _broadcastVoiceState(
        isInVoice: true,
        isTransmitting: false,
        channelId: _activeChannel?.id,
      );
      return;
    }

    // No modo Web (navegador), aciona diretamente o seletor nativo do navegador (getDisplayMedia)
    if (kIsWeb) {
      try {
        final screenTrack = await LocalVideoTrack.createScreenShareTrack(
          const ScreenShareCaptureOptions(
            params: VideoParametersPresets.screenShareH1080FPS30,
          ),
        );

        if (!mounted) {
          await screenTrack.stop();
          await screenTrack.dispose();
          return;
        }

        const config = ScreenShareConfig(
          sourceId: 'web_screen',
          title: 'Tela do Navegador',
          resolution: '1080p',
          fps: 30,
          type: 'screen',
          previewType: 'web',
          shareAudio: true,
        );

        // Se o usuário clicar em "Parar compartilhamento" na barra nativa do navegador
        screenTrack.mediaStreamTrack.onEnded = () {
          if (mounted && _isTransmitting) {
            _toggleTransmission();
          }
        };

        _startLiveStreamBroadcaster(config);

        setState(() {
          _isTransmitting = true;
          _activeScreenShareConfig = config;
          _localScreenShareTrack = screenTrack;
          _isInVoice = true;
          _isChatVisible = false;
          _isRightSidebarVisible = false;
          if (_activeChannel != null) {
            _connectedVoiceChannelId = _activeChannel!.id;
          }
        });
        _broadcastVoiceState(
          isInVoice: true,
          isTransmitting: true,
          streamTitle: config.title,
          previewType: config.previewType,
          thumbnail: config.thumbnail,
          channelId: _activeChannel?.id,
        );
      } catch (e) {
        debugPrint('[ScreenShare Web] Usuário cancelou ou erro no displayMedia: $e');
      }
      return;
    }

    if (!mounted) return;
    final activeChannelName = _activeChannel?.name ?? 'geral';
    final config = await ScreenShareDialog.show(
      context,
      accentColor: _selectedAccentColor,
      channelName: activeChannelName,
    );

    if (config != null && mounted) {
      LocalVideoTrack? screenTrack;
      try {
        String? targetSourceId = config.sourceId;
        try {
          final webrtcSources = await rtc.desktopCapturer.getSources(
            types: config.type == 'screen'
                ? [rtc.SourceType.Screen]
                : [rtc.SourceType.Window, rtc.SourceType.Screen],
          );

          if (webrtcSources.isNotEmpty) {
            rtc.DesktopCapturerSource? match;
            if (targetSourceId != null && targetSourceId.isNotEmpty) {
              match = webrtcSources.cast<rtc.DesktopCapturerSource?>().firstWhere(
                (s) => s?.id == targetSourceId,
                orElse: () => null,
              );
            }
            if (match == null) {
              final targetTitle = config.title.toLowerCase().trim();
              match = webrtcSources.cast<rtc.DesktopCapturerSource?>().firstWhere(
                (s) {
                  final name = s?.name.toLowerCase().trim() ?? '';
                  return name == targetTitle ||
                      name.contains(targetTitle) ||
                      targetTitle.contains(name);
                },
                orElse: () => webrtcSources.first,
              );
            }
            if (match != null) {
              targetSourceId = match.id;
            }
          }
        } catch (e) {
          debugPrint('[ScreenShare] WebRTC sources lookup notice: $e');
        }

        screenTrack = await LocalVideoTrack.createScreenShareTrack(
          ScreenShareCaptureOptions(
            sourceId: targetSourceId,
            params: VideoParametersPresets.screenShareH1080FPS30,
          ),
        );
      } catch (e) {
        debugPrint('[ScreenShare] Erro ao criar track WebRTC: $e');
      }

      // Always start broadcaster loop to sync continuous live frames to remote watchers
      _startLiveStreamBroadcaster(config);

      setState(() {
        _isTransmitting = true;
        _activeScreenShareConfig = config;
        _localScreenShareTrack = screenTrack;
        _isInVoice = true;
        _isChatVisible = false;
        _isRightSidebarVisible = false;
        if (_activeChannel != null) {
          _connectedVoiceChannelId = _activeChannel!.id;
        }
      });
      _broadcastVoiceState(
        isInVoice: true,
        isTransmitting: true,
        streamTitle: config.title,
        previewType: config.previewType,
        thumbnail: config.thumbnail,
        channelId: _activeChannel?.id,
      );
    }
  }

  Future<void> _saveCustomization() async {
    await ref.read(serversControllerProvider.notifier).updateServerCustomization(
      widget.server.id,
      bannerPreset: _selectedBannerPreset,
      accentColor: _selectedAccentColor.toARGB32(),
    );
    if (mounted) {
      setState(() => _isCustomizingBanner = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: _selectedAccentColor,
          content: Text(
            'Personalização salva com sucesso!',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  void _showMobileChannelsBottomSheet(
    BuildContext context,
    bool isDark,
    List<ChannelModel> effectiveChannels,
    String username,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141522) : const Color(0xFFFAF9F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusLg),
      ),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Consumer(
          builder: (modalContext, ref, _) {
            final liveVoiceState = ref.watch(voiceStateProvider);
            final liveVoiceNotifier = ref.read(voiceStateProvider.notifier);
            return SafeArea(
              top: false,
              bottom: true,
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(modalContext).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: AppRadius.borderPill,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ServerRightSidebar(
                        isDark: isDark,
                        server: widget.server,
                        channels: effectiveChannels,
                        activeChannel: _activeChannel,
                        username: username,
                        accentColor: _selectedAccentColor,
                        clientSessionId: _clientSessionId,
                        voiceParticipants: _voiceParticipants,
                        serverMembers: _serverMembers,
                        voiceState: liveVoiceState,
                        voiceNotifier: liveVoiceNotifier,
                        isInVoice: _isInVoice || liveVoiceState.isConnected,
                        width: double.infinity,
                        onChannelSelected: (c) {
                          Navigator.pop(ctx);
                          _openHybridChannel(c);
                        },
                        onWatchStream: (p) {
                          Navigator.pop(ctx);
                          setState(() {
                            _watchingRemoteStream = p;
                            _isChatVisible = false;
                            _isRightSidebarVisible = false;
                          });
                        },
                        onLeaveVoice: () {
                          Navigator.pop(ctx);
                          _leaveVoice();
                        },
                        onMembersUpdated: _loadServerMembers,
                        onToggleMic: _handleMicToggle,
                        onToggleDeafened: _handleDeafenToggle,
                        isTransmitting: _isTransmitting,
                        onToggleTransmission: _toggleTransmission,
                        connectedVoiceChannelId: _connectedVoiceChannelId ?? liveVoiceState.connectedChannelId,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHybridChannelStage(
    BuildContext context,
    bool isDark,
    String username,
    List<ChannelModel> channels,
    VoiceState voiceState,
    VoiceStateNotifier voiceNotifier,
  ) {
    final activeChannelName = _activeChannel?.name ?? 'geral';
    final channelKey = _activeChannel?.id ?? 'default';
    final messages = _channelMessages[channelKey] ?? [];

    final isStreamingOrWatching =
        _isTransmitting || _watchingRemoteStream != null;

    // CASO 1: SEM TRANSMISSÃO NEM ASSISTINDO -> Mostra o Chat diretamente em tela inteira
    if (!isStreamingOrWatching) {
      return ChannelChatView(
        isDark: isDark,
        activeChannelName: activeChannelName,
        channelKey: channelKey,
        username: username,
        messages: messages,
        messageController: _messageController,
        editMessageController: _editMessageController,
        scrollController: _scrollController,
        messageFocusNode: _messageFocusNode,
        editingMessageId: _editingMessageId,
        isTransmitting: _isTransmitting,
        isInVoice: _isInVoice,
        isConnectingVoice: _isConnectingLiveKit,
        isVoiceConnected: _isLiveKitConnected,
        isRightSidebarVisible: _isRightSidebarVisible,
        accentColor: _selectedAccentColor,
        activeBroadcaster: _activeBroadcaster,
        voiceParticipants: _voiceParticipants,
        clientSessionId: _clientSessionId,
        onToggleTransmission: _toggleTransmission,
        onToggleVoiceChannel: () {
          if (_isInVoice) {
            _leaveVoice();
          } else if (_activeChannel != null) {
            _connectToLiveKitVoice(_activeChannel!.id);
          }
        },
        onToggleRightSidebar: () => setState(
          () => _isRightSidebarVisible = !_isRightSidebarVisible,
        ),
        onWatchLive: () {
          if (_activeBroadcaster != null) {
            setState(() {
              _watchingRemoteStream = _activeBroadcaster;
              _isChatVisible = false;
              _isRightSidebarVisible = false;
            });
          }
        },
        onSendMessage: (cKey, author) => _sendMessage(cKey, author),
        onStartEditing: (mId) {
          final m = messages.firstWhere((element) => element.id == mId);
          _startEditingMessage(m);
        },
        onCancelEditing: _cancelEditing,
        onSaveEditing: (mId) => _saveEditedMessage(channelKey),
        onDeleteMessage: (mId) => _deleteMessage(channelKey, mId),
      );
    }

    // CASO 2: COM TRANSMISSÃO ATIVA OU ASSISTINDO -> Mostra Palco de Vídeo/Tela + Chat Flutuante HUD
    return Container(
      color: const Color(0xFF0C0D14),
      child: Stack(
        children: [
          // A. Palco Imersivo de Transmissão / Screen Share
          Positioned.fill(
            child: ImmersiveStreamPlayer(
              isDark: isDark,
              username: username,
              remoteParticipant: _watchingRemoteStream,
              activeScreenShareConfig: _activeScreenShareConfig,
              localScreenShareTrack: _localScreenShareTrack,
              webRTCStream: ref.watch(screenShareControllerProvider).remoteShare?.stream,
              accentColor: _selectedAccentColor,
              streamVolume: _streamVolume,
              onBackToChat: () => setState(() {
                _watchingRemoteStream = null;
                _isChatVisible = true;
              }),
            ),
          ),

          // B. Barra Inferior da Transmissão (Volume, Tela Cheia, PiP)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StreamStageBottomBar(
              isDark: isDark,
              username: username,
              remoteParticipant: _watchingRemoteStream,
              activeScreenShareConfig: _activeScreenShareConfig,
              streamVolume: _streamVolume,
              onVolumeChanged: (v) => setState(() => _streamVolume = v),
              isChatVisible: _isChatVisible,
              onToggleChat: () => setState(() => _isChatVisible = !_isChatVisible),
              isFullscreen: _isFullscreen,
              onToggleFullscreen: () =>
                  setState(() => _isFullscreen = !_isFullscreen),
              onStopOrLeave: () {
                if (_watchingRemoteStream != null) {
                  setState(() => _watchingRemoteStream = null);
                } else {
                  _toggleTransmission();
                }
              },
              accentColor: _selectedAccentColor,
            ),
          ),

          // C. Chat Flutuante HUD ou Botão Circular de Reabertura
          if (_isChatVisible)
            Positioned(
              top: 20,
              right: 20,
              width: 320,
              height: 440,
              child: FloatingChatHud(
                activeChannelName: activeChannelName,
                channelKey: channelKey,
                username: username,
                messages: messages,
                channels: channels,
                activeChannel: _activeChannel,
                messageController: _messageController,
                scrollController: _scrollController,
                messageFocusNode: _messageFocusNode,
                voiceState: voiceState,
                voiceNotifier: voiceNotifier,
                onClose: () => setState(() => _isChatVisible = false),
                onSelectChannel: (c) => _openHybridChannel(c),
                onSendMessage: (cKey, author) => _sendMessage(cKey, author),
                onStartEditing: (msg) => _startEditingMessage(msg),
                onDeleteMessage: (mId) => _deleteMessage(channelKey, mId),
                onLeaveVoice: _leaveVoice,
              ),
            )
          else
            Positioned(
              top: 20,
              right: 20,
              child: Tooltip(
                message: 'Abrir Chat',
                child: InkWell(
                  onTap: () => setState(() => _isChatVisible = true),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: AppRadius.borderPill,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13141F).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.messageSquare,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    ref.listen<AudioSettings>(audioSettingsProvider, (previous, next) {
      if (previous != next) {
        _updateLiveKitAudioProcessing(next);
      }
    });

    ref.listen<AudioDevicesState>(audioDevicesProvider, (previous, next) {
      if (previous?.selectedInputDeviceId != next.selectedInputDeviceId) {
        _updateLiveKitAudioDevice(next.selectedInputDeviceId);
      }
      if (previous?.selectedOutputDeviceId != next.selectedOutputDeviceId) {
        _updateLiveKitAudioOutputDevice(next.selectedOutputDeviceId);
      }
    });

    ref.listen<VoiceState>(voiceStateProvider, (previous, next) {
      if (previous?.isMicMuted != next.isMicMuted) {
        _applyMicState(next.isMicMuted);
      }
      if (previous?.isDeafened != next.isDeafened) {
        _applyDeafenState(next.isDeafened);
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final username = user?.username ?? 'Sr. 6Seven';

    final voiceState = ref.watch(voiceStateProvider);
    final voiceNotifier = ref.read(voiceStateProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final effectiveChannels = widget.server.channels.isNotEmpty
        ? widget.server.channels
        : [
            ChannelModel(
              id: 'chn_geral',
              serverId: widget.server.id,
              name: 'geral',
              type: ChannelType.hybrid,
            ),
          ];

    final stageWidget = _viewMode == ServerViewMode.home
        ? ServerHomeView(
            server: widget.server,
            isDark: isDark,
            username: username,
            channels: effectiveChannels,
            isTransmitting: _isTransmitting,
            selectedBannerPreset: _selectedBannerPreset,
            onSelectBannerPreset: (idx) =>
                setState(() => _selectedBannerPreset = idx),
            selectedAccentColor: _selectedAccentColor,
            onSelectAccentColor: (col) =>
                setState(() => _selectedAccentColor = col),
            isCustomizingBanner: _isCustomizingBanner,
            onToggleCustomizeBanner: () => setState(
              () => _isCustomizingBanner = !_isCustomizingBanner,
            ),
            onSaveCustomization: _saveCustomization,
            onOpenChannel: (c) => _openHybridChannel(c),
            voiceParticipants: _voiceParticipants,
            clientSessionId: _clientSessionId,
            connectedVoiceChannelId: _connectedVoiceChannelId,
            onJoinVoice: (c) => _connectToLiveKitVoice(c.id),
            onWatchStream: (p) => setState(() {
              _watchingRemoteStream = p;
              _isChatVisible = false;
              _isRightSidebarVisible = false;
            }),
          )
        : _buildHybridChannelStage(
            context,
            isDark,
            username,
            effectiveChannels,
            voiceState,
            voiceNotifier,
          );

    final topNavWidget = ServerTopNav(
      server: widget.server,
      isDark: isDark,
      viewMode: _viewMode,
      activeChannel: _activeChannel,
      accentColor: _selectedAccentColor,
      isRightSidebarVisible: _isRightSidebarVisible,
      isTransmitting: _isTransmitting,
      isInVoice: _isInVoice,
      isConnectingVoice: _isConnectingLiveKit,
      onToggleTransmission: _toggleTransmission,
      onToggleVoiceChannel: () {
        if (_isInVoice) {
          _leaveVoice();
        } else if (_activeChannel != null) {
          _connectToLiveKitVoice(_activeChannel!.id);
        }
      },
      totalInVoice: _voiceParticipants.values.fold<int>(
        0,
        (sum, m) => sum + m.values.where((p) => p.isInVoice).length,
      ),
      onBackToHome: () {
        if (_viewMode == ServerViewMode.channel) {
          setState(() {
            _viewMode = ServerViewMode.home;
            _watchingRemoteStream = null;
          });
        } else {
          widget.onBackToHome();
        }
      },
      onGoToHub: widget.onBackToHome,
      onInviteMembers: () => InviteMemberDialog.show(
        context,
        widget.server,
        onMembersUpdated: _loadServerMembers,
      ),
      onToggleRightSidebar: () => setState(
        () => _isRightSidebarVisible = !_isRightSidebarVisible,
      ),
      onOpenMobileChannelsSheet: () => _showMobileChannelsBottomSheet(
        context,
        isDark,
        effectiveChannels,
        username,
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          topNavWidget,
          Expanded(child: stageWidget),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Palco Principal: TopNav no topo + Conteúdo/Chat abaixo
        Expanded(
          child: Column(
            children: [
              topNavWidget,
              Expanded(child: stageWidget),
            ],
          ),
        ),

        // 2. Barra Lateral Direita: Estende-se até o topo junto à TopBar
        if (_isRightSidebarVisible)
          ServerRightSidebar(
            isDark: isDark,
            server: widget.server,
            channels: effectiveChannels,
            activeChannel: _activeChannel,
            username: username,
            accentColor: _selectedAccentColor,
            clientSessionId: _clientSessionId,
            voiceParticipants: _voiceParticipants,
            serverMembers: _serverMembers,
            voiceState: voiceState,
            voiceNotifier: voiceNotifier,
            isInVoice: _isInVoice,
            onChannelSelected: (c) => _openHybridChannel(c),
            onWatchStream: (p) => setState(() {
              _watchingRemoteStream = p;
              _isChatVisible = false;
              _isRightSidebarVisible = false;
            }),
            onLeaveVoice: _leaveVoice,
            onMembersUpdated: _loadServerMembers,
            onToggleMic: _handleMicToggle,
            onToggleDeafened: _handleDeafenToggle,
            isTransmitting: _isTransmitting,
            onToggleTransmission: _toggleTransmission,
            connectedVoiceChannelId: _connectedVoiceChannelId,
          ),
      ],
    );
  }
}