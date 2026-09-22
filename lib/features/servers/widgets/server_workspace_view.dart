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
  final ValueChanged<bool>? onRightSidebarVisibilityChanged;

  const ServerWorkspaceView({
    super.key,
    required this.server,
    required this.onBackToHome,
    this.onRightSidebarVisibilityChanged,
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
  bool? _lastReportedRightSidebarVisible;
  bool _isInVoice = false;
  bool _isConnectingLiveKit = false;
  bool _isLiveKitConnected = false;
  String? _connectedVoiceServerId;
  String? _connectedVoiceChannelId;
  Room? _liveKitRoom;
  Timer? _noiseGateReleaseTimer;
  Timer? _audioLevelDecayTimer;
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

  void _removeParticipantFromAllVoiceChannels(String? userId, [String? sessionId]) {
    for (final chMap in _voiceParticipants.values) {
      chMap.removeWhere((k, v) =>
          (userId != null && userId.isNotEmpty && (v.userId == userId || k == userId)) ||
          (sessionId != null && sessionId.isNotEmpty && (v.sessionId == sessionId || k == sessionId)));
    }
  }

  void _updateLocalAudioLevel(double level) {
    if (!mounted) return;
    _audioLevelDecayTimer?.cancel();
    _audioLevelDecayTimer = null;

    final voiceState = ref.read(voiceStateProvider);
    if (voiceState.isMicMuted || voiceState.isDeafened || !voiceState.isConnected) {
      if (ref.read(localAudioLevelProvider) != 0.0) {
        ref.read(localAudioLevelProvider.notifier).state = 0.0;
      }
      return;
    }

    ref.read(localAudioLevelProvider.notifier).state = level;

    // Quando o usuário para de falar, LiveKit pode parar de enviar eventos de active speakers.
    // Decaimento para 0.0 após 350ms sem novos eventos de voz para evitar que a barra fique travada.
    if (level > 0.0) {
      _audioLevelDecayTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted && ref.read(localAudioLevelProvider) != 0.0) {
          ref.read(localAudioLevelProvider.notifier).state = 0.0;
        }
      });
    }
  }

  void _processNoiseGate(double audioLevel) {
    if (!mounted || _liveKitRoom == null) return;
    final audioSettings = ref.read(audioSettingsProvider);
    final voiceState = ref.read(voiceStateProvider);

    // Se o microfone estiver mutado ou ensurdecido, fecha o gate e garante o track desabilitado
    if (voiceState.isMicMuted || voiceState.isDeafened) {
      if (_isGateOpen) {
        _noiseGateReleaseTimer?.cancel();
        _noiseGateReleaseTimer = null;
        _setLocalAudioTrackEnabled(false);
        _isGateOpen = false;
      }
      return;
    }

    // Se o auto noise gate estiver ativo, mantém a transmissão aberta
    if (audioSettings.autoNoiseGate) {
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
    final audioDevicesState = ref.read(audioDevicesProvider);
    final effectiveId = audioDevicesState.effectiveInputDeviceId;
    return audioSettings.toAudioCaptureOptions(deviceId: effectiveId);
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
      final audioDevicesState = ref.read(audioDevicesProvider);
      var targetId = (deviceId == 'default')
          ? (audioDevicesState.effectiveInputDeviceId ?? '')
          : deviceId;
      if (targetId.startsWith(r'SWD\MMDEVAPI\')) {
        targetId = targetId.replaceFirst(r'SWD\MMDEVAPI\', '');
      }
      if (targetId.startsWith(r'\')) {
        targetId = targetId.replaceFirst(RegExp(r'^\\+'), '');
      }
      targetId = targetId.trim().toLowerCase();

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
      final audioDevicesState = ref.read(audioDevicesProvider);
      var targetId = (deviceId == 'default')
          ? (audioDevicesState.effectiveOutputDeviceId ?? '')
          : deviceId;
      if (targetId.startsWith(r'SWD\MMDEVAPI\')) {
        targetId = targetId.replaceFirst(r'SWD\MMDEVAPI\', '');
      }
      if (targetId.startsWith(r'\')) {
        targetId = targetId.replaceFirst(RegExp(r'^\\+'), '');
      }
      targetId = targetId.trim().toLowerCase();
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
      final voiceState = ref.read(voiceStateProvider);
      final prevServerId = voiceState.connectedServerId ?? _connectedVoiceServerId;
      final prevChannelId = voiceState.connectedChannelId ?? _connectedVoiceChannelId;

      if (mounted) {
        setState(() {
          _isInVoice = true;
          _connectedVoiceServerId = widget.server.id;
          _connectedVoiceChannelId = channelId;
          _isConnectingLiveKit = true;
          _isLiveKitConnected = false;
        });
      }

      // Se o usuário estava em outro canal ou servidor de voz, notifica a saída
      if (prevServerId != null &&
          prevChannelId != null &&
          (prevServerId != widget.server.id || prevChannelId != channelId)) {
        _broadcastVoiceState(
          isInVoice: false,
          channelId: prevChannelId,
          serverId: prevServerId,
        );
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
          if (_watchingRemoteStream?.userId == event.participant.identity ||
              _watchingRemoteStream?.sessionId == event.participant.sid) {
            _setWatchingRemoteStream(null);
          }
        } else if (event is TrackPublishedEvent) {
          final uid = event.participant.identity;
          if (uid.isNotEmpty && _voiceParticipants[channelId]?[uid] != null) {
            if (event.publication.kind == TrackType.VIDEO) {
              _voiceParticipants[channelId]![uid] =
                  _voiceParticipants[channelId]![uid]!.copyWith(isTransmitting: true);
            }
          }
          final pub = event.publication;
          final isWatching = _watchingRemoteStream != null &&
              (_watchingRemoteStream!.userId == uid || _watchingRemoteStream!.sessionId == event.participant.sid);

          if (_isScreenShareAudio(pub, event.participant)) {
            if (!isWatching || _streamVolume <= 0) {
              try {
                pub.unsubscribe();
              } catch (_) {}
            }
          }
          _syncScreenShareAudioState();
          setState(() {});
        } else if (event is TrackUnpublishedEvent) {
          final uid = event.participant.identity;
          if (uid.isNotEmpty && _voiceParticipants[channelId]?[uid] != null) {
            if (event.publication.kind == TrackType.VIDEO) {
              _voiceParticipants[channelId]![uid] =
                  _voiceParticipants[channelId]![uid]!.copyWith(isTransmitting: false);
              if (_watchingRemoteStream?.userId == uid) {
                _setWatchingRemoteStream(null);
              }
            }
          }
          _syncScreenShareAudioState();
          setState(() {});
        } else if (event is TrackSubscribedEvent) {
          final uid = event.participant.identity;
          if (event.track is RemoteVideoTrack) {
            if (uid.isNotEmpty && _voiceParticipants[channelId]?[uid] != null) {
              _voiceParticipants[channelId]![uid] =
                  _voiceParticipants[channelId]![uid]!.copyWith(isTransmitting: true);
            }
          }
          final pub = event.publication;
          final isWatchingThisParticipant = _watchingRemoteStream != null &&
              (_watchingRemoteStream!.userId == uid ||
               _watchingRemoteStream!.sessionId == event.participant.sid);

          if (event.track is RemoteAudioTrack) {
            if (_isScreenShareAudio(pub, event.participant)) {
              final shouldEnable = isWatchingThisParticipant && _streamVolume > 0;
              if (!shouldEnable) {
                try {
                  pub.unsubscribe();
                } catch (_) {}
                event.track.disable();
                event.track.mediaStreamTrack.enabled = false;
              } else {
                event.track.enable();
                event.track.mediaStreamTrack.enabled = true;
              }
            } else {
              final isDeafened = ref.read(voiceStateProvider).isDeafened;
              if (isDeafened) {
                event.track.disable();
                event.track.mediaStreamTrack.enabled = false;
              } else {
                event.track.enable();
                event.track.mediaStreamTrack.enabled = true;
              }
            }
          }
          setState(() {});
        } else if (event is TrackUnsubscribedEvent) {
          if (event.track is RemoteVideoTrack) {
            final uid = event.participant.identity;
            if (uid.isNotEmpty && _voiceParticipants[channelId]?[uid] != null) {
              _voiceParticipants[channelId]![uid] =
                  _voiceParticipants[channelId]![uid]!.copyWith(isTransmitting: false);
            }
          }
          _syncScreenShareAudioState();
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
          final localIdentity = room.localParticipant?.identity;
          var localLevel = 0.0;
          for (final speaker in event.speakers) {
            if ((localSid != null && speaker.sid.isNotEmpty && speaker.sid == localSid) ||
                (localIdentity != null && speaker.identity.isNotEmpty && speaker.identity == localIdentity)) {
              localLevel = speaker.audioLevel;
              break;
            }
          }
          _updateLocalAudioLevel(localLevel);
          _processNoiseGate(localLevel);
        }
      });

      await room.connect(
        serverUrl,
        token,
      );

      // No Desktop, pré-seleciona explicitamente o microfone de entrada
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        final targetId = captureOptions.deviceId;
        if (targetId != null && targetId.isNotEmpty) {
          try {
            await rtc.Helper.selectAudioInput(targetId);
            debugPrint('[LiveKit] selectAudioInput pré-configurado na conexão: $targetId');
          } catch (e) {
            debugPrint('[LiveKit] selectAudioInput falhou na conexão: $e');
          }
        }
      }

      final currentVoiceState = ref.read(voiceStateProvider);
      final audioSettings = ref.read(audioSettingsProvider);
      final shouldMuteMic = currentVoiceState.isMicMuted ||
          currentVoiceState.isDeafened ||
          (audioSettings.isPushToTalk && !currentVoiceState.isPttPressed);

      if (audioSettings.isPushToTalk &&
          !currentVoiceState.isPttPressed &&
          !currentVoiceState.isMicMuted) {
        ref.read(voiceStateProvider.notifier).setMicMuted(true);
      }
      try {
        await room.localParticipant?.setMicrophoneEnabled(
          !shouldMuteMic,
          audioCaptureOptions: captureOptions,
        );
        debugPrint('[LiveKit] Microfone inicializado com sucesso (muted: $shouldMuteMic, device: ${captureOptions.deviceId})');
      } catch (e) {
        debugPrint('[LiveKit] Falha ao habilitar microfone com opções customizadas: $e, tentando fallback padrão...');
        try {
          await room.localParticipant?.setMicrophoneEnabled(!shouldMuteMic);
          debugPrint('[LiveKit] Microfone inicializado via fallback padrão');
        } catch (fallbackError) {
          debugPrint('[LiveKit] Fallback de microfone também falhou: $fallbackError');
        }
      }

      // Se já estiver ensurdecido ao conectar, muta o áudio de voz remoto imediatamente (preservando stream de vídeo/tela)
      if (currentVoiceState.isDeafened) {
        for (final remote in room.remoteParticipants.values) {
          for (final pub in remote.audioTrackPublications) {
            if (pub.source == TrackSource.screenShareAudio) {
              continue;
            }
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
      _syncScreenShareAudioState();

      if (mounted) {
        ref.read(voiceStateProvider.notifier).connectVoice(widget.server.id, channelId);
        setState(() {
          _isInVoice = true;
          _connectedVoiceServerId = widget.server.id;
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
        _broadcastVoiceState(
          isInVoice: true,
          channelId: channelId,
          serverId: widget.server.id,
          isConnecting: false,
        );
      }
      debugPrint('[LiveKit] Conectado na sala de voz com sucesso: $channelId');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInVoice = false;
          _connectedVoiceServerId = null;
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
        _audioLevelDecayTimer?.cancel();
        _audioLevelDecayTimer = null;
        _isGateOpen = true;
        if (mounted) {
          ref.read(localAudioLevelProvider.notifier).state = 0.0;
        }
        await _liveKitRoom?.disconnect();
        await _liveKitRoom?.dispose();
        if (mounted) {
          final currentUserId = ref.read(authControllerProvider).user?.id;
          _removeParticipantFromAllVoiceChannels(currentUserId, _clientSessionId);
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
      _removeParticipantFromAllVoiceChannels(uid, participant.sid.isNotEmpty ? participant.sid : null);
      if (joined) {
        final chMap = _voiceParticipants.putIfAbsent(channelId, () => {});
        chMap[uid] = VoiceParticipantInfo(
          sessionId: participant.sid.isNotEmpty ? participant.sid : uid,
          userId: uid,
          username: uname,
          serverId: widget.server.id,
          channelId: channelId,
          device: 'desktop',
          isInVoice: true,
          isConnecting: false,
          isTransmitting: false,
          isMuted: participant.isMuted,
          isDeafened: false,
          isSpeaking: participant.isSpeaking,
          updatedAt: DateTime.now(),
        );
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

  void _applyStreamVolume(double volume) {
    setState(() => _streamVolume = volume);
    _syncScreenShareAudioState();
  }

  bool _isScreenShareAudio(TrackPublication pub, Participant participant) {
    if (pub.kind != TrackType.AUDIO) return false;
    if (pub.source == TrackSource.screenShareAudio) {
      return true;
    }
    final name = pub.name.toLowerCase();
    if (name.contains('screen') ||
        name.contains('display') ||
        name.contains('share') ||
        name.contains('system') ||
        name.contains('desktop')) {
      return true;
    }
    if (pub.source != TrackSource.microphone && participant.audioTrackPublications.length > 1) {
      return true;
    }
    return false;
  }

  void _syncScreenShareAudioState() {
    if (_liveKitRoom == null) return;
    try {
      for (final remote in _liveKitRoom!.remoteParticipants.values) {
        final isWatchingThisParticipant = _watchingRemoteStream != null &&
            ((_watchingRemoteStream!.userId.isNotEmpty && _watchingRemoteStream!.userId == remote.identity) ||
             (_watchingRemoteStream!.sessionId.isNotEmpty && _watchingRemoteStream!.sessionId == remote.sid));
        final shouldEnableAudio = isWatchingThisParticipant && _streamVolume > 0;

        for (final pub in remote.audioTrackPublications) {
          if (_isScreenShareAudio(pub, remote)) {
            if (shouldEnableAudio) {
              if (!pub.subscribed) {
                try {
                  pub.subscribe();
                } catch (_) {}
              }
            } else {
              if (pub.subscribed) {
                try {
                  pub.unsubscribe();
                } catch (_) {}
              }
            }
            final t = pub.track;
            if (t != null) {
              if (shouldEnableAudio) {
                t.enable();
                t.mediaStreamTrack.enabled = true;
              } else {
                t.disable();
                t.mediaStreamTrack.enabled = false;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LiveKit] Erro ao sincronizar áudio de screen share: $e');
    }
  }

  void _setWatchingRemoteStream(VoiceParticipantInfo? participant) {
    setState(() {
      _watchingRemoteStream = participant;
      if (participant != null) {
        _isChatVisible = false;
        _isRightSidebarVisible = false;
      }
    });
    _syncScreenShareAudioState();
  }

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
    if (shouldMute) {
      _updateLocalAudioLevel(0.0);
    }
    try {
      final captureOptions = _buildAudioCaptureOptions();
      await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(
        !shouldMute,
        audioCaptureOptions: captureOptions,
      );
      _setLocalAudioTrackEnabled(!shouldMute);
      _isGateOpen = !shouldMute;
      if (shouldMute) {
        _noiseGateReleaseTimer?.cancel();
        _noiseGateReleaseTimer = null;
      }
      debugPrint('[LiveKit] Microfone alterado: isMuted=$isMuted, shouldMute=$shouldMute');
    } catch (e) {
      debugPrint('[LiveKit] Erro ao alterar microfone com opções: $e, tentando fallback...');
      try {
        await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(!shouldMute);
        _setLocalAudioTrackEnabled(!shouldMute);
        _isGateOpen = !shouldMute;
        if (shouldMute) {
          _noiseGateReleaseTimer?.cancel();
          _noiseGateReleaseTimer = null;
        }
      } catch (e2) {
        debugPrint('[LiveKit] Falha no fallback de microfone: $e2');
      }
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
            if (pub.source == TrackSource.screenShareAudio) {
              continue;
            }
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
        try {
          await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(
            !shouldMuteMic,
            audioCaptureOptions: captureOptions,
          );
        } catch (e) {
          await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(!shouldMuteMic);
        }
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
    String? serverId,
    bool? isMuted,
    bool? isDeafened,
  }) {
    final user = ref.read(authControllerProvider).user;
    final targetServerId = serverId ?? widget.server.id;
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
      'server_id': targetServerId,
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

    if (cid.isNotEmpty && targetServerId == widget.server.id) {
      setState(() {
        _removeParticipantFromAllVoiceChannels(uid, _clientSessionId);
        if (isInVoice) {
          final chMap = _voiceParticipants.putIfAbsent(cid, () => {});
          chMap[uid.isNotEmpty ? uid : _clientSessionId] = VoiceParticipantInfo.fromJson(payload);
        }
      });
    }

    try {
      ref.read(websocketClientProvider).sendEvent(
            'VOICE_STATE',
            payload,
            channelId: cid,
            serverId: targetServerId,
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
          // Remove de TODOS os canais primeiro para eliminar duplicatas e usuários desconectados
          _removeParticipantFromAllVoiceChannels(p.userId, p.sessionId);

          if (p.isInVoice) {
            final chMap = _voiceParticipants.putIfAbsent(chId, () => {});
            chMap[p.userId.isNotEmpty ? p.userId : p.key] = p;
            if (_watchingRemoteStream?.sessionId == p.sessionId ||
                _watchingRemoteStream?.userId == p.userId) {
              if (p.isTransmitting) {
                _watchingRemoteStream = p;
              } else {
                _watchingRemoteStream = null;
              }
            }
          } else {
            if (_watchingRemoteStream?.sessionId == p.sessionId ||
                _watchingRemoteStream?.userId == p.userId) {
              _watchingRemoteStream = null;
            }
          }
        });
        _syncScreenShareAudioState();
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
        final currentUserId = ref.read(authControllerProvider).user?.id ?? '';
        VoiceParticipantInfo? localVoiceInfo;
        final currentChannelId = _connectedVoiceChannelId;
        if (currentChannelId != null && _isInVoice && currentUserId.isNotEmpty) {
          final currentMap = _voiceParticipants[currentChannelId];
          if (currentMap != null) {
            localVoiceInfo = currentMap[currentUserId];
          }
        }

        // Limpa estado anterior para sincronizar exatamente com o snapshot autoritativo
        _voiceParticipants.clear();

        for (final item in list) {
          if (item is Map) {
            final p = VoiceParticipantInfo.fromJson(Map<String, dynamic>.from(item));
            if (p.channelId.isNotEmpty && p.isInVoice) {
              _removeParticipantFromAllVoiceChannels(p.userId, p.sessionId);
              final chMap = _voiceParticipants.putIfAbsent(p.channelId, () => {});
              chMap[p.userId.isNotEmpty ? p.userId : p.key] = p;
            }
          }
        }

        // Preserva o participante local caso ele esteja conectado e não tenha vindo ainda no sync
        if (_isInVoice && _connectedVoiceChannelId != null && currentUserId.isNotEmpty) {
          final userInSync = _voiceParticipants.values.any((m) => m.containsKey(currentUserId));
          if (!userInSync && localVoiceInfo != null) {
            final chMap = _voiceParticipants.putIfAbsent(_connectedVoiceChannelId!, () => {});
            chMap[currentUserId] = localVoiceInfo;
          }
        }

        // Valida se o stream que estava sendo assistido ainda está ativo
        if (_watchingRemoteStream != null) {
          final stillTransmitting = _voiceParticipants.values.any(
            (m) => m.values.any((v) =>
                (v.userId == _watchingRemoteStream!.userId || v.sessionId == _watchingRemoteStream!.sessionId) &&
                v.isTransmitting &&
                v.isInVoice),
          );
          if (!stillTransmitting) {
            _watchingRemoteStream = null;
          }
        }
      });
      _syncScreenShareAudioState();
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
        setState(() {
          _voiceParticipants.clear();
          _activeChannel = widget.server.channels.isNotEmpty ? widget.server.channels.first : null;
          _viewMode = ServerViewMode.home;
          _editingMessageId = null;
          _watchingRemoteStream = null;
          if (_connectedVoiceServerId != widget.server.id) {
            _isInVoice = false;
          }
        });
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
    _audioLevelDecayTimer?.cancel();
    _audioLevelDecayTimer = null;
    _streamRefreshTimer?.cancel();
    _localScreenShareTrack?.stop();
    _localScreenShareTrack?.dispose();
    _localScreenShareTrack = null;

    if (_isInVoice && _connectedVoiceChannelId != null) {
      final leavingServerId = _connectedVoiceServerId ?? widget.server.id;
      _broadcastVoiceState(
        isInVoice: false,
        channelId: _connectedVoiceChannelId,
        serverId: leavingServerId,
      );
    }

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
    final shouldJoin = joinVoice;
    final voiceState = ref.read(voiceStateProvider);
    final prevServerId = voiceState.connectedServerId ?? _connectedVoiceServerId;
    final prevChannelId = voiceState.connectedChannelId ?? _connectedVoiceChannelId;

    if (shouldJoin &&
        prevChannelId != null &&
        (prevChannelId != channel.id || (prevServerId != null && prevServerId != widget.server.id))) {
      _disconnectFromLiveKitVoice();
      final targetPrevServerId = prevServerId ?? widget.server.id;
      _broadcastVoiceState(
        isInVoice: false,
        channelId: prevChannelId,
        serverId: targetPrevServerId,
      );
    }
    final uid = ref.read(authControllerProvider).user?.id ?? '';
    final uname = ref.read(authControllerProvider).user?.username ?? 'Usuário';

    setState(() {
      _activeChannel = channel;
      _viewMode = ServerViewMode.channel;
      if (shouldJoin) {
        _isInVoice = true;
        _connectedVoiceServerId = widget.server.id;
        _connectedVoiceChannelId = channel.id;
        _isConnectingLiveKit = true;
        _isLiveKitConnected = false;

        if (uid.isNotEmpty) {
          _removeParticipantFromAllVoiceChannels(uid, _clientSessionId);
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
      _broadcastVoiceState(
        isInVoice: true,
        channelId: channel.id,
        serverId: widget.server.id,
        isConnecting: true,
      );
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
    final voiceState = ref.read(voiceStateProvider);
    final leavingServerId = _connectedVoiceServerId ?? voiceState.connectedServerId ?? widget.server.id;
    final leavingChannelId = _connectedVoiceChannelId ?? voiceState.connectedChannelId ?? _activeChannel?.id;
    final currentUserId = ref.read(authControllerProvider).user?.id ?? '';

    ref.read(voiceStateProvider.notifier).disconnectVoice();
    _streamRefreshTimer?.cancel();
    _localScreenShareTrack?.stop();
    _localScreenShareTrack?.dispose();
    _localScreenShareTrack = null;
    _disconnectFromLiveKitVoice();

    if (leavingChannelId != null && leavingChannelId.isNotEmpty && leavingServerId.isNotEmpty) {
      _broadcastVoiceState(
        isInVoice: false,
        channelId: leavingChannelId,
        serverId: leavingServerId,
      );
    }

    setState(() {
      _isInVoice = false;
      _isConnectingLiveKit = false;
      _isLiveKitConnected = false;
      _isTransmitting = false;
      _activeScreenShareConfig = null;
      _connectedVoiceServerId = null;
      _connectedVoiceChannelId = null;
      _isRightSidebarVisible = true;
      _viewMode = ServerViewMode.home;
      _watchingRemoteStream = null;

      _removeParticipantFromAllVoiceChannels(currentUserId, _clientSessionId);
    });
    _syncScreenShareAudioState();
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
      if (_liveKitRoom != null) {
        try {
          await _liveKitRoom!.localParticipant?.setScreenShareEnabled(false);
        } catch (_) {}
      }
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
        LocalVideoTrack? screenTrack;
        if (_liveKitRoom != null && _liveKitRoom!.localParticipant != null) {
          await _liveKitRoom!.localParticipant!.setScreenShareEnabled(
            true,
            captureScreenAudio: true,
          );
          for (final pub in _liveKitRoom!.localParticipant!.videoTrackPublications) {
            if (pub.track is LocalVideoTrack) {
              screenTrack = pub.track as LocalVideoTrack;
              break;
            }
          }
        } else {
          screenTrack = await LocalVideoTrack.createScreenShareTrack(
            const ScreenShareCaptureOptions(
              params: VideoParametersPresets.screenShareH1080FPS30,
            ),
          );
        }

        if (screenTrack == null) return;

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

        final captureOptions = ScreenShareCaptureOptions(
          sourceId: targetSourceId,
          params: config.fps == 15
              ? VideoParametersPresets.screenShareH1080FPS15
              : VideoParametersPresets.screenShareH1080FPS30,
          captureScreenAudio: config.shareAudio,
        );

        if (_liveKitRoom != null && _liveKitRoom!.localParticipant != null) {
          try {
            await _liveKitRoom!.localParticipant!.setScreenShareEnabled(
              true,
              captureScreenAudio: config.shareAudio,
              screenShareCaptureOptions: captureOptions,
            );
            for (final pub in _liveKitRoom!.localParticipant!.videoTrackPublications) {
              if (pub.track is LocalVideoTrack) {
                screenTrack = pub.track as LocalVideoTrack;
                break;
              }
            }
          } catch (e) {
            debugPrint('[LiveKit] setScreenShareEnabled falhou no Desktop: $e, tentando createScreenShareTrack...');
          }
        }

        if (screenTrack == null) {
          screenTrack = await LocalVideoTrack.createScreenShareTrack(captureOptions);
          if (_liveKitRoom != null && _liveKitRoom!.localParticipant != null) {
            try {
              await _liveKitRoom!.localParticipant!.publishVideoTrack(screenTrack);
            } catch (e) {
              debugPrint('[LiveKit] Erro ao publicar screenTrack no Desktop: $e');
            }
          }
        }
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
                        onJoinVoiceChannel: (c) {
                          Navigator.pop(ctx);
                          _openHybridChannel(c, joinVoice: true);
                        },
                        onWatchStream: (p) {
                          Navigator.pop(ctx);
                          _setWatchingRemoteStream(p);
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
        connectedVoiceChannelId: _connectedVoiceChannelId,
        onToggleTransmission: _toggleTransmission,
        onToggleVoiceChannel: () {
          if (_activeChannel == null) return;
          if (_isInVoice && _connectedVoiceChannelId == _activeChannel!.id) {
            _leaveVoice();
          } else {
            _openHybridChannel(_activeChannel!, joinVoice: true);
          }
        },
        onToggleRightSidebar: () => setState(
          () => _isRightSidebarVisible = !_isRightSidebarVisible,
        ),
        onWatchLive: () {
          if (_activeBroadcaster != null) {
            _setWatchingRemoteStream(_activeBroadcaster);
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
    VideoTrack? remoteVideoTrack;
    if (_watchingRemoteStream != null && _liveKitRoom != null) {
      final remoteUid = _watchingRemoteStream!.userId;
      final remoteSid = _watchingRemoteStream!.sessionId;
      for (final rp in _liveKitRoom!.remoteParticipants.values) {
        if (rp.identity == remoteUid || rp.sid == remoteSid) {
          for (final pub in rp.videoTrackPublications) {
            if (pub.track != null) {
              remoteVideoTrack = pub.track;
              break;
            }
          }
        }
      }
    }

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
              remoteVideoTrack: remoteVideoTrack,
              webRTCStream: ref.watch(screenShareControllerProvider).remoteShare?.stream,
              accentColor: _selectedAccentColor,
              streamVolume: _streamVolume,
              onBackToChat: () => _setWatchingRemoteStream(null),
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
              onVolumeChanged: _applyStreamVolume,
              isChatVisible: _isChatVisible,
              onToggleChat: () => setState(() => _isChatVisible = !_isChatVisible),
              isFullscreen: _isFullscreen,
              onToggleFullscreen: () =>
                  setState(() => _isFullscreen = !_isFullscreen),
              onStopOrLeave: () {
                if (_watchingRemoteStream != null) {
                  _setWatchingRemoteStream(null);
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
    if (_lastReportedRightSidebarVisible != _isRightSidebarVisible) {
      _lastReportedRightSidebarVisible = _isRightSidebarVisible;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRightSidebarVisibilityChanged?.call(_isRightSidebarVisible);
      });
    }

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

    ref.listen<AudioSettings>(audioSettingsProvider, (previous, next) {
      if (previous?.isPushToTalk != next.isPushToTalk) {
        if (next.isPushToTalk) {
          final currentVoice = ref.read(voiceStateProvider);
          if (!currentVoice.isPttPressed && !currentVoice.isMicMuted) {
            ref.read(voiceStateProvider.notifier).setMicMuted(true);
          }
        }
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
            onJoinVoice: (c) => _openHybridChannel(c, joinVoice: true),
            onWatchStream: (p) => _setWatchingRemoteStream(p),
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
      connectedVoiceChannelId: _connectedVoiceChannelId,
      onToggleTransmission: _toggleTransmission,
      onToggleVoiceChannel: () {
        if (_activeChannel == null) return;
        if (_isInVoice && _connectedVoiceChannelId == _activeChannel!.id) {
          _leaveVoice();
        } else {
          _openHybridChannel(_activeChannel!, joinVoice: true);
        }
      },
      totalInVoice: _voiceParticipants.values.fold<int>(
        0,
        (sum, m) => sum + m.values.where((p) => p.isInVoice).length,
      ),
      onBackToHome: () {
        if (_viewMode == ServerViewMode.channel) {
          setState(() => _viewMode = ServerViewMode.home);
          _setWatchingRemoteStream(null);
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
            onJoinVoiceChannel: (c) => _openHybridChannel(c, joinVoice: true),
            onWatchStream: (p) => _setWatchingRemoteStream(p),
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
