import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/invite_member_dialog.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/services/desktop_hardware_service.dart';
import 'package:projectnbx/features/voice/widgets/screen_share_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ServerViewMode { home, channel }

enum ServerSidebarTab { canais, membros, resumo }

class _VoiceParticipantInfo {
  final String sessionId;
  final String userId;
  final String username;
  final String serverId;
  final String channelId;
  final String device;
  final bool isInVoice;
  final bool isTransmitting;
  final String? streamTitle;
  final String? previewType;
  final String? thumbnail;
  final bool isMuted;
  final bool isDeafened;
  final bool isSpeaking;
  final DateTime updatedAt;

  const _VoiceParticipantInfo({
    required this.sessionId,
    required this.userId,
    required this.username,
    required this.serverId,
    required this.channelId,
    this.device = 'desktop',
    this.isInVoice = true,
    this.isTransmitting = false,
    this.streamTitle,
    this.previewType,
    this.thumbnail,
    this.isMuted = false,
    this.isDeafened = false,
    this.isSpeaking = false,
    required this.updatedAt,
  });

  String get key => sessionId.isNotEmpty ? sessionId : userId;

  factory _VoiceParticipantInfo.fromJson(Map<String, dynamic> json) {
    return _VoiceParticipantInfo(
      sessionId: (json['session_id'] ?? json['user_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      username: (json['username'] ?? 'Usuário').toString(),
      serverId: (json['server_id'] ?? '').toString(),
      channelId: (json['channel_id'] ?? '').toString(),
      device: (json['device'] ?? 'desktop').toString(),
      isInVoice: json['is_in_voice'] == true,
      isTransmitting: json['is_transmitting'] == true,
      streamTitle: json['stream_title']?.toString(),
      previewType: json['preview_type']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      isMuted: json['is_muted'] == true,
      isDeafened: json['is_deafened'] == true,
      isSpeaking: json['is_speaking'] == true,
      updatedAt: DateTime.now(),
    );
  }
}

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
  final Map<String, List<_ChatMessage>> _channelMessages = {};

  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  String? _editingMessageId;
  ServerViewMode _viewMode = ServerViewMode.home;
  ServerSidebarTab _activeSidebarTab = ServerSidebarTab.canais;
  ChannelModel? _activeChannel;

  int _selectedBannerPreset = 0;
  Color _selectedAccentColor = const Color(0xFFF5CBA7);
  bool _isCustomizingBanner = false;

  bool _isRightSidebarVisible = true;
  bool _isInVoice = false;
  String? _connectedVoiceChannelId;

  late final String _clientSessionId =
      'sess_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
  final Map<String, Map<String, _VoiceParticipantInfo>> _voiceParticipants = {};
  _VoiceParticipantInfo? _watchingRemoteStream;

  List<_VoiceParticipantInfo> _getChannelVoiceParticipants(String channelId) {
    final map = _voiceParticipants[channelId];
    if (map == null) return [];
    return map.values.where((p) => p.isInVoice).toList();
  }

  _VoiceParticipantInfo? get _activeBroadcaster {
    if (_activeChannel == null) return null;
    final map = _voiceParticipants[_activeChannel!.id];
    if (map == null) return null;
    for (final p in map.values) {
      if (p.isInVoice && p.isTransmitting && p.sessionId != _clientSessionId) {
        return p;
      }
    }
    return null;
  }

  // Real stream / screen share transmission state
  bool _isTransmitting = false;
  ScreenShareConfig? _activeScreenShareConfig;
  LocalVideoTrack? _localScreenShareTrack;
  Timer? _streamRefreshTimer;
  double _streamVolume = 0.75;
  bool _isChatVisible = false;
  bool _isFullscreen = false;

  List<Map<String, dynamic>> _serverMembers = [];

  final List<List<Color>> _bannerPresets = [
    [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF4338CA)],
    [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
    [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF059669)],
    [const Color(0xFF450A0A), const Color(0xFF7F1D1D), const Color(0xFF991B1B)],
    [const Color(0xFF3B0764), const Color(0xFF581C87), const Color(0xFF6B21A8)],
  ];

  final List<Color> _accentPalette = [
    const Color(0xFFF5CBA7), // Pastel Peach
    const Color(0xFF4ADE80), // Pastel Sage
    const Color(0xFF38BDF8), // Cyan Blue
    const Color(0xFFF87171), // Coral Red
    const Color(0xFFC084FC), // Soft Lavender
  ];

  @override
  void initState() {
    super.initState();
    _selectedBannerPreset = widget.server.bannerPreset.clamp(
      0,
      _bannerPresets.length - 1,
    );
    _selectedAccentColor = Color(widget.server.accentColor);
    if (widget.server.channels.isNotEmpty) {
      _activeChannel = widget.server.channels.first;
    }
    _loadPersistedMessages();
    _loadServerMembers();
    _initWebSocketAndSync();
  }

  void _broadcastVoiceState({
    required bool isInVoice,
    bool? isTransmitting,
    String? streamTitle,
    String? previewType,
    String? thumbnail,
    String? channelId,
  }) {
    final user = ref.read(authControllerProvider).user;
    final cid =
        channelId ?? _connectedVoiceChannelId ?? _activeChannel?.id ?? '';
    final uname = (user?.username ?? '').isNotEmpty ? user!.username : 'Você';
    final uid = user?.id ?? 'user_${_clientSessionId.hashCode.abs()}';
    final transmitting = isTransmitting ?? _isTransmitting;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final deviceStr = isMobile ? 'mobile' : 'desktop';

    final payload = <String, dynamic>{
      'session_id': _clientSessionId,
      'user_id': uid,
      'username': uname,
      'server_id': widget.server.id,
      'channel_id': cid,
      'device': deviceStr,
      'is_in_voice': isInVoice,
      'is_transmitting': transmitting,
      if (streamTitle != null || _activeScreenShareConfig?.title != null)
        'stream_title': streamTitle ?? _activeScreenShareConfig?.title,
      if (previewType != null || _activeScreenShareConfig?.previewType != null)
        'preview_type': previewType ?? _activeScreenShareConfig?.previewType,
      if (thumbnail != null || _activeScreenShareConfig?.thumbnail != null)
        'thumbnail': thumbnail ?? _activeScreenShareConfig?.thumbnail,
    };

    if (cid.isNotEmpty) {
      setState(() {
        final chMap = _voiceParticipants.putIfAbsent(cid, () => {});
        if (isInVoice) {
          chMap[_clientSessionId] = _VoiceParticipantInfo.fromJson(payload);
        } else {
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

      if (_isInVoice && _connectedVoiceChannelId != null) {
        _broadcastVoiceState(
          isInVoice: true,
          channelId: _connectedVoiceChannelId,
        );
      }
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
    if (rawPayload is Map<String, dynamic>) {
      payload = rawPayload;
    } else if (rawPayload is String) {
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        }
      } catch (_) {}
    }

    if (type == 'VOICE_STATE') {
      final p = _VoiceParticipantInfo.fromJson(payload);
      final chId = p.channelId.isNotEmpty
          ? p.channelId
          : (event['channel_id'] ?? _activeChannel?.id ?? '').toString();
      if (chId.isNotEmpty) {
        setState(() {
          final chMap = _voiceParticipants.putIfAbsent(chId, () => {});
          if (p.isInVoice) {
            chMap[p.key] = p;
            if (_watchingRemoteStream?.sessionId == p.sessionId ||
                _watchingRemoteStream?.userId == p.userId) {
              _watchingRemoteStream = p;
            }
          } else {
            chMap.remove(p.key);
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
          if (item is Map<String, dynamic>) {
            final p = _VoiceParticipantInfo.fromJson(item);
            if (p.channelId.isNotEmpty && p.isInVoice) {
              _voiceParticipants.putIfAbsent(p.channelId, () => {})[p.key] = p;
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
      final newMsg = _ChatMessage.fromApi(payload, _selectedAccentColor);
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
              _scrollController.position.maxScrollExtent,
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
      final Map<String, List<_ChatMessage>> loaded = {};

      for (final key in keys) {
        final chKey = key.substring(prefix.length);
        final rawJson = prefs.getString(key);
        if (rawJson != null && rawJson.isNotEmpty) {
          try {
            final list = (jsonDecode(rawJson) as List<dynamic>)
                .map(
                  (item) => _ChatMessage.fromJson(item as Map<String, dynamic>),
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
            .map((m) => _ChatMessage.fromApi(m, _selectedAccentColor))
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
          _bannerPresets.length - 1,
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
    _streamRefreshTimer?.cancel();
    _localScreenShareTrack?.stop();
    _localScreenShareTrack?.dispose();
    _localScreenShareTrack = null;
    _wsSubscription?.cancel();
    _messageController.dispose();
    _editMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getAuthorInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed
        .split(RegExp(r'[\s_\-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    final single = parts.isNotEmpty ? parts.first : trimmed;
    if (single.length >= 2) {
      return single.substring(0, 2).toUpperCase();
    }
    return single.toUpperCase();
  }

  Color _resolveAuthorColor(String name, bool isDark) {
    const darkPalette = [
      Color(0xFF38BDF8), // Sky Blue
      Color(0xFFC084FC), // Lavender / Soft Purple
      Color(0xFFF472B6), // Pink
      Color(0xFFFBBF24), // Amber / Warm Gold
      Color(0xFF34D399), // Emerald / Mint
      Color(0xFFFB923C), // Orange / Coral
      Color(0xFFA78BFA), // Pastel Violet
      Color(0xFF2DD4BF), // Cyan / Teal
      Color(0xFFF87171), // Pastel Red / Salmon
      Color(0xFFA3E635), // Pastel Lime
      Color(0xFF67E8F9), // Light Cyan
      Color(0xFFE879F9), // Fuchsia / Magenta
    ];
    const lightPalette = [
      Color(0xFF0284C7), // Deep Sky Blue
      Color(0xFF7C3AED), // Deep Purple
      Color(0xFFDB2777), // Deep Pink
      Color(0xFFD97706), // Deep Amber
      Color(0xFF059669), // Deep Emerald
      Color(0xFFEA580C), // Deep Orange
      Color(0xFF4F46E5), // Indigo
      Color(0xFF0D9488), // Deep Teal
      Color(0xFFDC2626), // Deep Red
      Color(0xFF65A30D), // Deep Lime
      Color(0xFF0891B2), // Deep Cyan
      Color(0xFFC026D3), // Deep Magenta
    ];
    final palette = isDark ? darkPalette : lightPalette;
    if (name.trim().isEmpty) return palette[0];
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }

  Widget _buildChatAvatar(String initials, Color color, bool isDark) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.45 : 0.6),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String channelKey, String authorName) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final targetChannelId = _activeChannel?.id ?? channelKey;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tempId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
    final newMsg = _ChatMessage(
      id: tempId,
      author: authorName,
      authorColor: _resolveAuthorColor(authorName, isDark),
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _channelMessages.putIfAbsent(targetChannelId, () => []).add(newMsg);
      _messageController.clear();
    });

    await _saveChannelMessages(targetChannelId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    // Send via WebSocket if connected, otherwise fallback to HTTP REST API
    final wsClient = ref.read(websocketClientProvider);
    if (wsClient.isConnected) {
      wsClient.sendEvent(
        'CHAT_MESSAGE',
        {'content': text},
        channelId: targetChannelId,
        serverId: widget.server.id,
      );
    } else {
      try {
        final apiClient = ref.read(apiClientProvider);
        final res = await apiClient.sendMessage(
          widget.server.id,
          targetChannelId,
          text,
        );
        if (res != null && res['id'] != null && mounted) {
          final realId = res['id'].toString();
          setState(() {
            final list = _channelMessages[targetChannelId];
            if (list != null) {
              final idx = list.indexWhere((m) => m.id == tempId);
              if (idx != -1) {
                list[idx] = list[idx].copyWith(id: realId);
              }
            }
          });
          await _saveChannelMessages(targetChannelId);
        }
      } catch (_) {}
    }
  }

  void _startEditingMessage(_ChatMessage msg) {
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

  void _openHybridChannel(ChannelModel channel) {
    final prevChannelId = _connectedVoiceChannelId;
    if (prevChannelId != null && prevChannelId != channel.id) {
      _broadcastVoiceState(isInVoice: false, channelId: prevChannelId);
    }
    setState(() {
      _activeChannel = channel;
      _viewMode = ServerViewMode.channel;
      _isInVoice = true;
      _connectedVoiceChannelId = channel.id;
    });
    ref.read(serversControllerProvider.notifier).selectChannel(channel.id);
    _loadChannelFromApi(channel.id);
    _broadcastVoiceState(isInVoice: true, channelId: channel.id);
  }

  Future<void> _loadChannelFromApi(String channelId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final apiMsgs = await apiClient.getMessages(widget.server.id, channelId);
      if (mounted) {
        final mapped = apiMsgs.map((m) {
          final authorName = (m['author'] is Map)
              ? (m['author']['username'] ?? 'Usuário')
              : (m['author_id'] ?? 'Usuário');
          return _ChatMessage(
            id: (m['id'] ?? 'msg_${DateTime.now().microsecondsSinceEpoch}')
                .toString(),
            author: authorName.toString(),
            authorColor: _selectedAccentColor,
            content: (m['content'] ?? '').toString(),
            isEdited: m['is_edited'] == true,
            timestamp: m['created_at'] != null
                ? DateTime.tryParse(m['created_at'].toString())
                : null,
          );
        }).toList();

        setState(() {
          _channelMessages[channelId] = mapped;
        });
        await _saveChannelMessages(channelId);
      }
    } catch (_) {}
  }

  void _leaveVoice() {
    _streamRefreshTimer?.cancel();
    _localScreenShareTrack?.stop();
    _localScreenShareTrack?.dispose();
    _localScreenShareTrack = null;
    final prevChannelId = _connectedVoiceChannelId ?? _activeChannel?.id;
    setState(() {
      _isInVoice = false;
      _isTransmitting = false;
      _activeScreenShareConfig = null;
      _connectedVoiceChannelId = null;
      _isRightSidebarVisible = true;
      _viewMode = ServerViewMode.home;
      _watchingRemoteStream = null;
    });
    if (prevChannelId != null && prevChannelId.isNotEmpty) {
      _broadcastVoiceState(
        isInVoice: false,
        isTransmitting: false,
        channelId: prevChannelId,
      );
    }
  }

  void _startLiveStreamPollingFallback(ScreenShareConfig config) {
    _streamRefreshTimer?.cancel();
    _streamRefreshTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      if (!mounted || !_isTransmitting || _localScreenShareTrack != null) {
        _streamRefreshTimer?.cancel();
        return;
      }
      try {
        const hardwareService = DesktopHardwareService();
        final all = await hardwareService.getAllSources();
        if (!mounted || !_isTransmitting) return;
        final list = config.type == 'screen' ? all.screens : all.windows;
        String? newThumb;
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
        if (newThumb != null && newThumb != _activeScreenShareConfig?.thumbnail && mounted) {
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
          _broadcastVoiceState(
            isInVoice: true,
            isTransmitting: true,
            streamTitle: config.title,
            previewType: config.previewType,
            thumbnail: newThumb,
            channelId: _activeChannel?.id,
          );
        }
      } catch (_) {}
    });
  }

  Future<void> _toggleTransmission() async {
    if (_isTransmitting) {
      _streamRefreshTimer?.cancel();
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

      if (screenTrack == null) {
        _startLiveStreamPollingFallback(config);
      }

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

  @override
  Widget build(BuildContext context) {
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

    return Column(
      children: [
        // 1. Sub-Header Navigation Bar
        _buildServerTopNav(
          context,
          isDark,
          username,
          effectiveChannels,
          voiceState,
          voiceNotifier,
        ),

        // 2. Main Body: Stage (Home OR Hybrid Channel Stage) + Right Sidebar
        Expanded(
          child: isMobile
              ? (_viewMode == ServerViewMode.home
                    ? _buildServerHomeContent(
                        context,
                        isDark,
                        username,
                        effectiveChannels,
                      )
                    : _buildHybridChannelStage(
                        context,
                        isDark,
                        username,
                        effectiveChannels,
                        voiceState,
                        voiceNotifier,
                      ))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Stage (Home, Direct Chat, or Immersive Stream + HUD)
                    Expanded(
                      child: _viewMode == ServerViewMode.home
                          ? _buildServerHomeContent(
                              context,
                              isDark,
                              username,
                              effectiveChannels,
                            )
                          : _buildHybridChannelStage(
                              context,
                              isDark,
                              username,
                              effectiveChannels,
                              voiceState,
                              voiceNotifier,
                            ),
                    ),

                    // Right Sidebar (Canais | Membros | Resumo)
                    if (_isRightSidebarVisible)
                      _buildRightSidebar(
                        context,
                        isDark,
                        effectiveChannels,
                        username,
                        voiceState,
                        voiceNotifier,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 1. SERVER SUB-HEADER NAVIGATION BAR
  // ===========================================================================
  Widget _buildServerTopNav(
    BuildContext context,
    bool isDark,
    String username,
    List<ChannelModel> effectiveChannels,
    VoiceState voiceState,
    VoiceStateNotifier voiceNotifier,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back to Hub Button
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            tooltip: 'Voltar ao Hub Principal',
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            onPressed: widget.onBackToHome,
          ),

          if (!isMobile) ...[
            const SizedBox(width: 4),
            // Hub Pill Button (Between back arrow and server name)
            InkWell(
              onTap: () => setState(() => _viewMode = ServerViewMode.home),
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _viewMode == ServerViewMode.home
                      ? _selectedAccentColor
                      : (isDark
                            ? const Color(0xFF1E2030)
                            : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _viewMode == ServerViewMode.home
                        ? Colors.transparent
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.layoutGrid,
                      size: 13,
                      color: _viewMode == ServerViewMode.home
                          ? Colors.black
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hub',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _viewMode == ServerViewMode.home
                            ? Colors.black
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Server Name (Without server icon)
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.server.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: isMobile ? 13.5 : 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_viewMode == ServerViewMode.channel &&
                    _activeChannel != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '/',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '# ${_activeChannel!.name}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedAccentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Invite / Add Members Button
          InkWell(
            onTap: () => InviteMemberDialog.show(
              context,
              widget.server,
              onMembersUpdated: _loadServerMembers,
            ),
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _selectedAccentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedAccentColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.userPlus,
                    size: 13,
                    color: _selectedAccentColor,
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Convidar',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          if (isMobile) ...[
            // Mobile Channels / Members Sheet Toggle
            IconButton(
              icon: Icon(
                _viewMode == ServerViewMode.channel
                    ? LucideIcons.layers
                    : LucideIcons.menu,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              tooltip: 'Canais e Membros',
              onPressed: () {
                _showMobileChannelsBottomSheet(
                  context,
                  isDark,
                  effectiveChannels,
                  username,
                  voiceState,
                  voiceNotifier,
                );
              },
            ),
          ] else ...[
            // Right Sidebar Collapse/Expand Toggle (Desktop)
            Tooltip(
              message: _isRightSidebarVisible
                  ? 'Recolher painel lateral'
                  : 'Expandir painel lateral',
              child: InkWell(
                onTap: () => setState(
                  () => _isRightSidebarVisible = !_isRightSidebarVisible,
                ),
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2030)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Icon(
                    _isRightSidebarVisible
                        ? LucideIcons.panelRightClose
                        : LucideIcons.panelRightOpen,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMobileChannelsBottomSheet(
    BuildContext context,
    bool isDark,
    List<ChannelModel> effectiveChannels,
    String username,
    VoiceState voiceState,
    VoiceStateNotifier voiceNotifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141522) : const Color(0xFFFAF9F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header Tabs: Canais | Membros | Resumo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? const Color(0xFF202234) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildSidebarTabButton(
                          title: 'Canais',
                          tab: ServerSidebarTab.canais,
                          icon: LucideIcons.volume2,
                          isDark: isDark,
                        ),
                        _buildSidebarTabButton(
                          title: 'Membros',
                          tab: ServerSidebarTab.membros,
                          icon: LucideIcons.users,
                          isDark: isDark,
                        ),
                        _buildSidebarTabButton(
                          title: 'Resumo',
                          tab: ServerSidebarTab.resumo,
                          icon: LucideIcons.barChart2,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  // Tab Content
                  Expanded(
                    child: _buildSidebarTabContent(isDark, effectiveChannels, username),
                  ),
                  // Voice Connection Status
                  _buildDockedVoiceFooter(isDark, voiceState, voiceNotifier),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 2. HYBRID CHANNEL STAGE
  // ===========================================================================
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
      return _buildDirectChatView(
        context,
        isDark,
        activeChannelName,
        channelKey,
        username,
        messages,
      );
    }

    // CASO 2: COM TRANSMISSÃO ATIVA OU ASSISTINDO -> Mostra Palco de Vídeo/Tela + Chat Flutuante HUD
    return Container(
      color: const Color(0xFF0C0D14),
      child: Stack(
        children: [
          // A. Palco Imersivo de Transmissão / Screen Share
          Positioned.fill(
            child: _buildImmersiveStreamPlayer(
              isDark,
              username,
              remoteParticipant: _watchingRemoteStream,
            ),
          ),

          // B. Barra Inferior da Transmissão (Volume, Tela Cheia, PiP)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStageBottomControlBar(
              isDark,
              username,
              remoteParticipant: _watchingRemoteStream,
            ),
          ),

          // C. Chat Flutuante HUD (Glassmorphism Overlay) ou Botão Circular Flutuante de Abrir
          if (_isChatVisible)
            Positioned(
              top: 20,
              right: 20,
              width: 320,
              height: 440,
              child: _buildFloatingChatHud(
                context,
                isDark,
                activeChannelName,
                channelKey,
                username,
                messages,
                channels,
                voiceState,
                voiceNotifier,
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
                  borderRadius: BorderRadius.circular(9999),
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
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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

  // Visualização Direta do Chat (quando NÃO há transmissão ativa)
  Widget _buildDirectChatView(
    BuildContext context,
    bool isDark,
    String activeChannelName,
    String channelKey,
    String username,
    List<_ChatMessage> messages,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: isDark ? const Color(0xFF13141F) : const Color(0xFFFAF9F6),
      child: Column(
        children: [
          // Channel Header Bar
          Container(
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141522) : const Color(0xFFFFFFFF),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF202234)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.hash, size: 18, color: _selectedAccentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          activeChannelName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: isMobile ? 14.5 : 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Canal Híbrido · Texto, Voz e Transmissão integrados',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : AppColors.lightTextMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Transmitir Tela Button
                if (isMobile)
                  IconButton(
                    onPressed: _toggleTransmission,
                    icon: Icon(
                      _isTransmitting
                          ? LucideIcons.screenShareOff
                          : LucideIcons.screenShare,
                      size: 18,
                      color: _isTransmitting
                          ? const Color(0xFFEF4444)
                          : _selectedAccentColor,
                    ),
                    tooltip: _isTransmitting
                        ? 'Parar Transmissão'
                        : 'Transmitir Tela',
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _toggleTransmission,
                    icon: Icon(
                      _isTransmitting
                          ? LucideIcons.screenShareOff
                          : LucideIcons.screenShare,
                      size: 14,
                    ),
                    label: Text(
                      _isTransmitting ? 'Parar Transmissão' : 'Transmitir Tela',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTransmitting
                          ? const Color(0xFFEF4444)
                          : _selectedAccentColor,
                      foregroundColor: _isTransmitting
                          ? Colors.white
                          : (_selectedAccentColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Active Live Stream Banner if someone is transmitting
          if (_activeBroadcaster != null)
            _buildActiveLiveStreamBanner(isDark, _activeBroadcaster!),

          // Message Feed (Real messages or welcome empty state)
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2030)
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedAccentColor.withValues(
                                  alpha: 0.4,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.hash,
                                size: 28,
                                color: _selectedAccentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bem-vindo ao #$activeChannelName!',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Este é o início do canal #$activeChannelName no servidor ${widget.server.name}.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Envie uma mensagem abaixo para começar a conversar!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isEditing = _editingMessageId == msg.id;
                        final isMine =
                            msg.author == username || msg.author == 'Você';
                        final initials = _getAuthorInitials(msg.author);
                        final authorColor =
                            _resolveAuthorColor(msg.author, isDark);

                        if (isMine) {
                          // MY MESSAGE (WhatsApp Style -> Aligned to the Right)
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Action Icons (Edit / Delete) to the left of the sent bubble
                                if (!isEditing) ...[
                                  Tooltip(
                                    message: 'Editar mensagem',
                                    child: InkWell(
                                      onTap: () => _startEditingMessage(msg),
                                      mouseCursor: SystemMouseCursors.click,
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          LucideIcons.pencil,
                                          size: 13,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Tooltip(
                                    message: 'Excluir mensagem',
                                    child: InkWell(
                                      onTap: () => _deleteMessage(
                                        channelKey,
                                        msg.id,
                                      ),
                                      mouseCursor: SystemMouseCursors.click,
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          LucideIcons.trash2,
                                          size: 13,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],

                                // Sent Message Bubble (Emerald / Green Tinted)
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          isMobile ? screenWidth * 0.78 : 520,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF16382B)
                                          : const Color(0xFFD9FDD3),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(4),
                                      ),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF265742)
                                                .withValues(alpha: 0.7)
                                            : const Color(0xFFB7E4AF),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.22 : 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: isEditing
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF141520)
                                                      : const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: _selectedAccentColor,
                                                    width: 1.2,
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: TextField(
                                                  controller:
                                                      _editMessageController,
                                                  autofocus: true,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13.5,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A,
                                                          ),
                                                  ),
                                                  cursorColor:
                                                      _selectedAccentColor,
                                                  decoration:
                                                      const InputDecoration(
                                                    border: InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    focusedErrorBorder:
                                                        InputBorder.none,
                                                    disabledBorder:
                                                        InputBorder.none,
                                                    isDense: true,
                                                    filled: false,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                  ),
                                                  onSubmitted: (_) =>
                                                      _saveEditedMessage(
                                                    channelKey,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Enter para ',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : const Color(
                                                              0xFF64748B,
                                                            ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () =>
                                                        _saveEditedMessage(
                                                      channelKey,
                                                    ),
                                                    mouseCursor:
                                                        SystemMouseCursors
                                                            .click,
                                                    child: Text(
                                                      'salvar',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            _selectedAccentColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    ' • ',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF94A3B8,
                                                            )
                                                          : const Color(
                                                              0xFF64748B,
                                                            ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: _cancelEditing,
                                                    mouseCursor:
                                                        SystemMouseCursors
                                                            .click,
                                                    child: Text(
                                                      'cancelar',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                          0xFFEF4444,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                msg.content,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5,
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.95,
                                                        )
                                                      : const Color(
                                                          0xFF0F172A,
                                                        ),
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  if (msg.isEdited) ...[
                                                    Text(
                                                      'editada ',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFFA7D5C0,
                                                              )
                                                            : const Color(
                                                                0xFF4B775C,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                  if (msg.timestamp != null)
                                                    Text(
                                                      '${msg.timestamp!.hour.toString().padLeft(2, '0')}:${msg.timestamp!.minute.toString().padLeft(2, '0')}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10.5,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFFA7D5C0,
                                                              )
                                                            : const Color(
                                                                0xFF4B775C,
                                                              ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Sender Avatar on the Right with Initials
                                _buildChatAvatar(initials, authorColor, isDark),
                              ],
                            ),
                          );
                        } else {
                          // RECEIVED MESSAGE (From others -> Aligned to the Left)
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Author Avatar on the Left with Initials
                                _buildChatAvatar(initials, authorColor, isDark),
                                const SizedBox(width: 8),

                                // Received Message Bubble (Neutral Card with Author Name Header)
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          isMobile ? screenWidth * 0.78 : 520,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E2030)
                                          : const Color(0xFFFFFFFF),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF313244)
                                            : const Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.22 : 0.04,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Author name in distinct color
                                        Text(
                                          msg.author,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: authorColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          msg.content,
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.92,
                                                  )
                                                : const Color(0xFF1E293B),
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (msg.isEdited) ...[
                                              Text(
                                                'editada ',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic,
                                                  color: isDark
                                                      ? const Color(
                                                          0xFF64748B,
                                                        )
                                                      : const Color(
                                                          0xFF94A3B8,
                                                        ),
                                                ),
                                              ),
                                            ],
                                            if (msg.timestamp != null)
                                              Text(
                                                '${msg.timestamp!.hour.toString().padLeft(2, '0')}:${msg.timestamp!.minute.toString().padLeft(2, '0')}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  color: isDark
                                                      ? const Color(
                                                          0xFF64748B,
                                                        )
                                                      : const Color(
                                                          0xFF94A3B8,
                                                        ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
          ),

          // Message Input Bar matching Prototype
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2030)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E314A)
                      : const Color(0xFFCBD5E1),
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {},
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(9999),
                    child: Icon(
                      LucideIcons.plusCircle,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      cursorColor: _selectedAccentColor,
                      decoration: InputDecoration(
                        hintText: 'Mensagem em #$activeChannelName',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(channelKey, username),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {},
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(9999),
                    child: Icon(
                      LucideIcons.smile,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _sendMessage(channelKey, username),
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(9999),
                    child: Icon(
                      LucideIcons.send,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLiveStreamBanner(
    bool isDark,
    _VoiceParticipantInfo broadcaster,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1428) : const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFA855F7).withValues(alpha: isDark ? 0.6 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'AO VIVO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${broadcaster.username} está transmitindo',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  broadcaster.streamTitle ?? 'Tela Principal',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _watchingRemoteStream = broadcaster;
                _isChatVisible = false;
                _isRightSidebarVisible = false;
              });
            },
            icon: const Icon(LucideIcons.play, size: 13),
            label: const Text(
              'Assistir Live',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Palco de Transmissão Imersiva com Vídeo ao Vivo, Som e Telemetria
  Widget _buildImmersiveStreamPlayer(
    bool isDark,
    String username, {
    _VoiceParticipantInfo? remoteParticipant,
  }) {
    final isRemote = remoteParticipant != null;
    final title = isRemote
        ? (remoteParticipant.streamTitle ?? 'Transmissão')
        : (_activeScreenShareConfig?.title ?? 'Tela Principal');
    final resolution = _activeScreenShareConfig?.resolution ?? '1080p';
    final fps = _activeScreenShareConfig?.fps ?? 60;
    final previewType = isRemote
        ? (remoteParticipant.previewType ?? 'nbx')
        : (_activeScreenShareConfig?.previewType ?? 'nbx');
    final shareAudio = isRemote
        ? true
        : (_activeScreenShareConfig?.shareAudio ?? true);
    final broadcasterName = isRemote ? remoteParticipant.username : username;
    final thumb = isRemote
        ? remoteParticipant.thumbnail
        : _activeScreenShareConfig?.thumbnail;

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF090A10)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Screen / Window Video Feed Canvas
          Positioned.fill(
            child: _buildLiveStreamContent(
              previewType,
              title,
              broadcasterName,
              isDark,
              remoteThumbnail: thumb,
            ),
          ),

          // 2. Top HUD Overlay (Live Badge, App Name, Telemetry, Audio Meter)
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 740;
                final isVeryCompact = constraints.maxWidth < 560;

                return Row(
                  children: [
                    // Live Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AO VIVO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Active Window / App Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: _selectedAccentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.screenShare,
                              size: 13,
                              color: _selectedAccentColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!isVeryCompact) ...[
                      const SizedBox(width: 8),
                      // SFU Realtime Telemetry Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          isCompact ? '$resolution $fps FPS' : '$resolution • $fps FPS • 6.8 Mbps',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Live Audio Visualizer Equalizer (if audio enabled)
                    if (shareAudio && _streamVolume > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.volume2,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 5),
                              Text(
                                'ÁUDIO',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                            const SizedBox(width: 5),
                            _buildMiniAudioEqualizer(),
                          ],
                        ),
                      ),

                    if (isRemote) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _watchingRemoteStream = null;
                            _isRightSidebarVisible = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.arrowLeft,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Voltar ao Chat',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // 3. Subtle Vignette & Gradient Edges
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.15, 0.85, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Live Screen Content Stream (Real-Time WebRTC Video Track or Active Capture Fallback)
  Widget _buildLiveStreamContent(
    String previewType,
    String title,
    String username,
    bool isDark, {
    String? remoteThumbnail,
  }) {
    if (_localScreenShareTrack != null) {
      return Container(
        color: const Color(0xFF090A10),
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoTrackRenderer(
              _localScreenShareTrack!,
              fit: VideoViewFit.contain,
            ),
          ),
        ),
      );
    }

    // Fallback: If we have a real captured thumbnail from PrintWindow or CopyFromScreen, display it in the player!
    final thumbB64 = remoteThumbnail ?? _activeScreenShareConfig?.thumbnail;
    if (thumbB64 != null && thumbB64.isNotEmpty) {
      try {
        final bytes = base64Decode(thumbB64);
        return Container(
          color: const Color(0xFF090A10),
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      } catch (_) {}
    }

    switch (previewType) {
      case 'youtube':
        return _buildYouTubeStreamViewport(title);
      case 'android_studio':
        return _buildAndroidStudioStreamViewport();
      case 'goland':
        return _buildGoLandStreamViewport();
      case 'figma':
        return _buildFigmaStreamViewport();
      case 'github':
        return _buildGitHubStreamViewport();
      case 'whatsapp':
        return _buildWhatsAppStreamViewport();
      case 'rgb':
        return _buildRgbStreamViewport();
      case 'vscode':
        return _buildVsCodeStreamViewport();
      case 'chrome':
        return _buildChromeStreamViewport();
      case 'spotify':
        return _buildSpotifyStreamViewport();
      case 'terminal':
        return _buildTerminalStreamViewport();
      case 'game':
        return _buildGameStreamViewport();
      case 'screen1':
      case 'screen2':
        return _buildDesktopMonitorViewport(title);
      case 'discord':
        return _buildDiscordStreamViewport();
      case 'nbx':
      default:
        return _buildProjectNbxStreamViewport();
    }
  }

  // YouTube Live Stream Viewport
  Widget _buildYouTubeStreamViewport(String title) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          // Video Player Screen
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop with subtle gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [Color(0xFF2A1515), Color(0xFF0A0A0A)],
                    ),
                  ),
                ),
                // Center Player Overlay
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF0000).withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0000),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AO VIVO',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'YouTube 1080p60 HDR • 48 kHz Stereo Audio',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Player Bottom Scrubber Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow, size: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        const Icon(Icons.volume_up, size: 18, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          '24:10 / 1:12:00',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                width: 220,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Positioned(
                                left: 216,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF0000),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'HD 1080',
                            style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.fullscreen, size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Android Studio Stream Viewport
  Widget _buildAndroidStudioStreamViewport() {
    return Container(
      color: const Color(0xFF1E1F22),
      child: Column(
        children: [
          // Android Studio Window Tab Header
          Container(
            height: 36,
            color: const Color(0xFF2B2D30),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.android, size: 16, color: Color(0xFF3DDC84)),
                const SizedBox(width: 8),
                Text('projectNBX — [D:\\Github\\My\\projectNBX]', style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70)),
                const Spacer(),
                const Icon(Icons.play_arrow, size: 16, color: Color(0xFF3DDC84)),
                const SizedBox(width: 8),
                const Icon(Icons.bug_report, size: 16, color: Color(0xFFE8BF6A)),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, size: 16, color: Color(0xFF38BDF8)),
              ],
            ),
          ),
          // Code Area + Project Tree
          Expanded(
            child: Row(
              children: [
                // Project Explorer
                Container(
                  width: 160,
                  color: const Color(0xFF1E1F22),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROJECT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                      const SizedBox(height: 8),
                      _buildTreeItem(Icons.folder, 'lib', const Color(0xFF6897BB), isExpanded: true),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTreeItem(Icons.folder, 'features', const Color(0xFF6897BB)),
                            _buildTreeItem(Icons.folder, 'core', const Color(0xFF6897BB)),
                            _buildTreeItem(LucideIcons.fileCode2, 'main.dart', const Color(0xFF3DDC84), isSelected: true),
                          ],
                        ),
                      ),
                      _buildTreeItem(LucideIcons.fileText, 'pubspec.yaml', const Color(0xFFE8BF6A)),
                    ],
                  ),
                ),
                Container(width: 1, color: const Color(0xFF2B2D30)),
                // Editor with Code
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E1F22),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCodeLine('import \'package:flutter/material.dart\';', const Color(0xFFCC7832)),
                        _buildCodeLine('import \'package:flutter_riverpod/flutter_riverpod.dart\';', const Color(0xFFCC7832)),
                        _buildCodeLine('import \'package:projectnbx/features/home/screens/home_screen.dart\';', const Color(0xFFCC7832)),
                        _buildCodeLine('', Colors.transparent),
                        _buildCodeLine('void main() async {', const Color(0xFFFFC66D)),
                        _buildCodeLine('  WidgetsFlutterBinding.ensureInitialized();', const Color(0xFF9876AA)),
                        _buildCodeLine('  runApp(const ProviderScope(child: ProjectNBXApp()));', const Color(0xFF9876AA)),
                        _buildCodeLine('}', const Color(0xFFFFC66D)),
                        const Spacer(),
                        // Bottom Run Bar
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B2D30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF3DDC84)),
                              const SizedBox(width: 6),
                              Text(
                                'Running on Windows (Desktop) • Hot Reload active (214ms)',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF3DDC84)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GoLand Stream Viewport
  Widget _buildGoLandStreamViewport() {
    return Container(
      color: const Color(0xFF1E1F22),
      child: Column(
        children: [
          Container(
            height: 36,
            color: const Color(0xFF2B2D30),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(LucideIcons.code2, size: 16, color: Color(0xFF00ADD8)),
                const SizedBox(width: 8),
                Text('backend — GoLand 2024.1', style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70)),
                const Spacer(),
                Text('Go 1.22.4', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF00ADD8))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _buildCodeLine('package database', const Color(0xFFCC7832)),
                _buildCodeLine('', Colors.transparent),
                _buildCodeLine('// ConnectDB establishes high performance pooling with Postgres 16', const Color(0xFF629755)),
                _buildCodeLine('func ConnectDB(cfg *config.Config) (*sqlx.DB, error) {', const Color(0xFFFFC66D)),
                _buildCodeLine('    db, err := sqlx.Open("postgres", cfg.DatabaseURL)', const Color(0xFF00ADD8)),
                _buildCodeLine('    if err != nil { return nil, err }', const Color(0xFFCC7832)),
                _buildCodeLine('    db.SetMaxOpenConns(50)', const Color(0xFF6897BB)),
                _buildCodeLine('    db.SetMaxIdleConns(10)', const Color(0xFF6897BB)),
                _buildCodeLine('    return db, nil', const Color(0xFFCC7832)),
                _buildCodeLine('}', const Color(0xFFFFC66D)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2D30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: Color(0xFF00ADD8)),
                      const SizedBox(width: 6),
                      Text(
                        'Tests passed: 18 of 18 (100% coverage on audit_repository)',
                        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF00ADD8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  // Figma Stream Viewport
  Widget _buildFigmaStreamViewport() {
    return Container(
      color: const Color(0xFF2C2C2C),
      child: Column(
        children: [
          // Figma Header
          Container(
            height: 38,
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(LucideIcons.penTool, size: 16, color: Color(0xFFF24E1E)),
                const SizedBox(width: 8),
                Text('ProjectNBX — Design System 2.0', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0D99FF), borderRadius: BorderRadius.circular(4)),
                  child: Text('Share', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          // Canvas Area
          Expanded(
            child: Row(
              children: [
                // Layers
                Container(
                  width: 140,
                  color: const Color(0xFF252525),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LAYERS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                      const SizedBox(height: 8),
                      Text('❖ ScreenShareModal', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFF24E1E))),
                      Text('  ↳ TopBarHUD', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                      Text('  ↳ SourceGrid (16:9)', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                      Text('  ↳ SoundwaveEqualizer', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                // Center Canvas
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E1E1E),
                    child: Center(
                      child: Container(
                        width: 320,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF181926),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF24E1E), width: 1.5),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.screenShare, size: 36, color: _selectedAccentColor),
                              const SizedBox(height: 8),
                              Text('Discord-Like Screen Share UI', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Real Windows & Monitors Enumerable', style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GitHub Desktop Stream Viewport
  Widget _buildGitHubStreamViewport() {
    return Container(
      color: const Color(0xFF1F2428),
      child: Column(
        children: [
          Container(
            height: 38,
            color: const Color(0xFF24292E),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(LucideIcons.gitBranch, size: 16, color: Color(0xFF8957E5)),
                const SizedBox(width: 8),
                Text('Current Repository: projectNBX', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 14),
                Text('Current Branch: main', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF8957E5))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2 changed files in working tree', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileCode2, size: 14, color: Color(0xFF3FB950)),
                        const SizedBox(width: 8),
                        Text('lib/features/voice/widgets/screen_share_dialog.dart', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white70)),
                        const Spacer(),
                        Text('+182 -14', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF3FB950))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileCode2, size: 14, color: Color(0xFF3FB950)),
                        const SizedBox(width: 8),
                        Text('lib/features/servers/widgets/server_workspace_view.dart', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white70)),
                        const Spacer(),
                        Text('+220 -8', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF3FB950))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WhatsApp Desktop Stream Viewport
  Widget _buildWhatsAppStreamViewport() {
    return Container(
      color: const Color(0xFF111B21),
      child: Row(
        children: [
          Container(
            width: 180,
            color: const Color(0xFF202C33),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.messageCircle, size: 18, color: Color(0xFF25D366)),
                    const SizedBox(width: 8),
                    Text('Conversas', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF111B21), borderRadius: BorderRadius.circular(6)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dev Team NBX', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Transmissão ao vivo iniciada!', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF25D366))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF0B141A),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005C4B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'A transmissão via LiveKit está rodando em 1080p 60FPS!',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202C33),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sensacional! A latência está em menos de 20ms.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SignalRGB Chroma Stream Viewport
  Widget _buildRgbStreamViewport() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF831843),
            Color(0xFF312E81),
            Color(0xFF064E3B),
            Color(0xFF78350F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEC4899), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.palette, size: 48, color: Color(0xFFEC4899)),
                  const SizedBox(height: 12),
                  Text('SignalRGB Pro — Chroma Lighting Canvas', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('All Peripherals Synchronized to LiveKit Stream Soundwave', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeItem(IconData icon, String name, Color color, {bool isExpanded = false, bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            name,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF3DDC84) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // VS Code Stream Viewport Simulation
  Widget _buildVsCodeStreamViewport() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // Editor Tab Bar
          Container(
            height: 34,
            color: const Color(0xFF252526),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    border: Border(top: BorderSide(color: Color(0xFF38BDF8), width: 2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileCode2, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text('server_handler.go', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: const Color(0xFF2D2D2D),
                  child: Text('websocket_client.dart', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white54)),
                ),
                const Spacer(),
                const Icon(LucideIcons.split, size: 14, color: Colors.white54),
                const SizedBox(width: 8),
                const Icon(LucideIcons.moreHorizontal, size: 14, color: Colors.white54),
              ],
            ),
          ),
          // Code Area + Minimap
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers
                Container(
                  width: 42,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFF1E1E1E),
                  child: Column(
                    children: List.generate(16, (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.2),
                      child: Text(
                        '${i + 1}'.padLeft(2, ' '),
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF858585)),
                      ),
                    )),
                  ),
                ),
                // Code Lines with Syntax Colors
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCodeLine('package handlers', const Color(0xFFC586C0)),
                        _buildCodeLine('', Colors.transparent),
                        _buildCodeLine('// SendMessage transmits chat and triggers live stream SFU', const Color(0xFF6A9955)),
                        _buildCodeLine('func (h *ServerHandler) SendMessage(w http.ResponseWriter, r *http.Request) {', const Color(0xFFDCDCAA)),
                        _buildCodeLine('    vars := mux.Vars(r)', const Color(0xFF9CDCFE)),
                        _buildCodeLine('    serverID := vars["id"]', const Color(0xFF9CDCFE)),
                        _buildCodeLine('    channelID := vars["channelId"]', const Color(0xFF9CDCFE)),
                        _buildCodeLine('    msg := models.NewMessage(serverID, channelID, req.Content)', const Color(0xFF4EC9B0)),
                        _buildCodeLine('    h.hub.BroadcastEvent(&models.WSEvent{', const Color(0xFFDCDCAA)),
                        _buildCodeLine('        Type: models.EventChatMessage,', const Color(0xFF4FC1FF)),
                        _buildCodeLine('        Payload: msg.ToJSON(),', const Color(0xFFCE9178)),
                        _buildCodeLine('        ChannelID: channelID,', const Color(0xFF9CDCFE)),
                        _buildCodeLine('    })', const Color(0xFFDCDCAA)),
                        _buildCodeLine('    w.WriteHeader(http.StatusCreated)', const Color(0xFF569CD6)),
                        _buildCodeLine('}', const Color(0xFFDCDCAA)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Integrated Bottom Terminal Output
          Container(
            height: 90,
            color: const Color(0xFF181818),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('TERMINAL', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(width: 8),
                    Text('zsh (ProjectNBX)', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF38BDF8))),
                  ],
                ),
                const SizedBox(height: 6),
                Text('➜  projectNBX git:(main) go run ./cmd/api', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF4ADE80))),
                Text('[LiveKit] SFU Room "geral" audio/video track published at 60 FPS (Opus 48kHz)', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFFF5CBA7))),
                Text('[WS] Hub active • 2 clients connected • Zero frame drops', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF38BDF8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeLine(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.2),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // Google Chrome Stream Viewport
  Widget _buildChromeStreamViewport() {
    return Container(
      color: const Color(0xFF1E2028),
      child: Column(
        children: [
          // Chrome Tab Bar & URL
          Container(
            color: const Color(0xFF2B2D3A),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2028),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.globe, size: 12, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          Text('LiveKit SFU WebRTC Docs', style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2028),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 12, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 6),
                      Text('https://docs.livekit.io/realtime/sfu/performance', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Web Page Documentation Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ProjectNBX Ultra-Low Latency Architecture', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Using LiveKit WebRTC SFU with adaptive bitrate (Dynacast), DTX, and Opus 48kHz audio encoding.', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildDocCard('SFU Gateway', '12ms Latency', const Color(0xFF38BDF8)),
                      const SizedBox(width: 14),
                      _buildDocCard('Audio Track', '48kHz Opus Stereo', const Color(0xFF4ADE80)),
                      const SizedBox(width: 14),
                      _buildDocCard('Video Track', '1080p 60 FPS VP9', const Color(0xFFF5CBA7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(String title, String subtitle, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF262835),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  // Spotify Stream Viewport
  Widget _buildSpotifyStreamViewport() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F3820), Color(0xFF0A0F0D), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1DB954), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.35),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.music, size: 54, color: Color(0xFF1DB954)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Developer Focus Beats (Lo-Fi)', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('ProjectNBX Live Audio Stream • 48 kHz High Fidelity', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1DB954))),
            const SizedBox(height: 18),
            // Dynamic Bouncing Soundwave Bars
            SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(18, (i) {
                  final heights = [12, 22, 18, 30, 14, 34, 26, 16, 28, 20, 32, 18, 24, 14, 28, 20, 16, 10];
                  final h = heights[i % heights.length];
                  return Container(
                    width: 4,
                    height: h.toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Windows Terminal Stream Viewport
  Widget _buildTerminalStreamViewport() {
    return Container(
      color: const Color(0xFF0C0C0C),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.squareTerminal, size: 16, color: Color(0xFF4ADE80)),
              const SizedBox(width: 8),
              Text('PowerShell 7.4.2 — ProjectNBX Dev Suite', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          Text('PS D:\\projectNBX> .\\scripts\\deploy_cluster.ps1', style: GoogleFonts.jetBrainsMono(fontSize: 13, color: const Color(0xFF4ADE80))),
          const SizedBox(height: 8),
          Text('[INFO] Initializing PostgreSQL 16 migration cluster...', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white60)),
          Text('[INFO] LiveKit SFU running on udp://0.0.0.0:7880', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF38BDF8))),
          Text('[SUCCESS] WebSocket broadcast stream online on :8080/ws', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF4ADE80))),
          Text('[ACTIVE] Streaming 1080p 60FPS to channel #geral', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFFF5CBA7))),
        ],
      ),
    );
  }

  // Game / Racing Simulator Viewport
  Widget _buildGameStreamViewport() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _RacingStreamCanvasPainter()),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('248 KM/H', style: GoogleFonts.jetBrainsMono(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444))),
              Text('GEAR 6 • 8200 RPM', style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Container(
                width: 240,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 190,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFFEF4444)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop Monitor Viewport
  Widget _buildDesktopMonitorViewport(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Floating simulated windows
          Positioned(
            top: 60,
            left: 50,
            width: 360,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2030),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
              ),
              child: Column(
                children: [
                  Container(
                    height: 26,
                    color: const Color(0xFF181926),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text('ProjectNBX Dev Workspace', style: GoogleFonts.inter(fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(LucideIcons.terminal, size: 36, color: _selectedAccentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Taskbar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 38,
            child: Container(
              color: const Color(0xFF0B0C12),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(LucideIcons.layoutGrid, size: 18, color: _selectedAccentColor),
                  const SizedBox(width: 14),
                  const Icon(LucideIcons.terminal, size: 16, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.globe, size: 16, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.music, size: 16, color: Colors.white70),
                  const Spacer(),
                  Text(
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ProjectNBX Native Stream Viewport
  Widget _buildProjectNbxStreamViewport() {
    return Container(
      color: const Color(0xFF141520),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedAccentColor.withValues(alpha: 0.4),
                ),
                boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 28)],
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.screenShare, size: 48, color: _selectedAccentColor),
                  const SizedBox(height: 12),
                  Text('ProjectNBX Live Workspace', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Stream de Alta Performance • Zero Frame Drop', style: GoogleFonts.inter(fontSize: 12, color: _selectedAccentColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Discord Stream Viewport
  Widget _buildDiscordStreamViewport() {
    return Container(
      color: const Color(0xFF313338),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left Sidebar channels
          Container(
            width: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2D31),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NBX COMMUNITY', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.hash, size: 14, color: Color(0xFF5865F2)),
                    const SizedBox(width: 6),
                    Text('geral', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.volume2, size: 14, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 6),
                    Text('Voz Geral', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Chat Stream
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF313338),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5865F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.messageSquare, size: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dev Squad', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Transmitindo tela com latência de 14ms', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAudioEqualizer() {
    return Row(
      children: List.generate(4, (i) {
        final heights = [6, 12, 8, 14];
        return Container(
          width: 2.5,
          height: heights[i].toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 1.2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  // Barra Inferior da Transmissão
  Widget _buildStageBottomControlBar(
    bool isDark,
    String username, {
    _VoiceParticipantInfo? remoteParticipant,
  }) {
    final isRemote = remoteParticipant != null;
    final title = isRemote
        ? (remoteParticipant.streamTitle ?? 'Transmissão de Tela')
        : (_activeScreenShareConfig?.title ?? 'Transmissão de Tela');
    final resolution = _activeScreenShareConfig?.resolution ?? '1080p';
    final fps = _activeScreenShareConfig?.fps ?? 60;
    final shareAudio = isRemote
        ? true
        : (_activeScreenShareConfig?.shareAudio ?? true);
    final displayName = isRemote ? remoteParticipant.username : username;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.94)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 740;
          final isVeryCompact = constraints.maxWidth < 560;

          return Row(
            children: [
              // Live Indicator Badge
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFEF4444),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AO VIVO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '$displayName — $title',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isVeryCompact) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCompact ? '$fps FPS' : '$resolution $fps FPS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Audio Mute/Volume Control (working)
              if (shareAudio) ...[
                IconButton(
                  icon: Icon(
                    _streamVolume == 0
                        ? LucideIcons.volumeX
                        : LucideIcons.volume2,
                    size: 16,
                    color: _streamVolume > 0
                        ? const Color(0xFF4ADE80)
                        : Colors.white70,
                  ),
                  tooltip: _streamVolume == 0 ? 'Ativar Som' : 'Silenciar',
                  onPressed: () {
                    setState(() {
                      _streamVolume = _streamVolume == 0 ? 0.75 : 0;
                    });
                  },
                ),
                if (!isVeryCompact) ...[
                  SizedBox(
                    width: isCompact ? 50 : 80,
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        trackHeight: 3,
                        activeTrackColor: const Color(0xFF4ADE80),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xFF4ADE80),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: _streamVolume,
                        onChanged: (val) =>
                            setState(() => _streamVolume = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],

              // Chat Visibility HUD Toggle
              IconButton(
                icon: Icon(
                  _isChatVisible
                      ? LucideIcons.messageSquare
                      : LucideIcons.messageSquareOff,
                  size: 16,
                  color:
                      _isChatVisible ? _selectedAccentColor : Colors.white70,
                ),
                tooltip:
                    _isChatVisible ? 'Ocultar Chat HUD' : 'Mostrar Chat HUD',
                onPressed: () =>
                    setState(() => _isChatVisible = !_isChatVisible),
              ),

              const SizedBox(width: 4),

              // Fullscreen Toggle
              IconButton(
                icon: Icon(
                  _isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
                  size: 16,
                  color: Colors.white70,
                ),
                tooltip: 'Tela Cheia',
                onPressed: () =>
                    setState(() => _isFullscreen = !_isFullscreen),
              ),

              const SizedBox(width: 8),

              // Stop Stream or Leave Stream Button
              ElevatedButton.icon(
                onPressed: () {
                  if (isRemote) {
                    setState(() {
                      _watchingRemoteStream = null;
                      _isRightSidebarVisible = true;
                    });
                  } else {
                    _toggleTransmission();
                  }
                },
                icon: Icon(
                  isRemote ? LucideIcons.logOut : LucideIcons.screenShareOff,
                  size: 14,
                ),
                label: Text(
                  isRemote
                      ? (isCompact ? 'Sair' : 'Sair da Live')
                      : (isCompact ? 'Parar' : 'Parar Transmissão'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Floating Glassmorphism Chat HUD
  Widget _buildFloatingChatHud(
    BuildContext context,
    bool isDark,
    String activeChannelName,
    String channelKey,
    String username,
    List<_ChatMessage> messages,
    List<ChannelModel> channels,
    VoiceState voiceState,
    VoiceStateNotifier voiceNotifier,
  ) {
    // Dynamic text/hybrid channels from real server data
    final effectiveChannels = channels
        .where(
          (c) => c.type == ChannelType.text || c.type == ChannelType.hybrid,
        )
        .toList();
    final displayChannels = effectiveChannels.isNotEmpty
        ? effectiveChannels
        : (channels.isNotEmpty
              ? channels
              : [
                  ChannelModel(
                    id: _activeChannel?.id ?? 'chn_geral',
                    serverId: widget.server.id,
                    name: activeChannelName,
                    type: _activeChannel?.type ?? ChannelType.text,
                  ),
                ]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13141F).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2E3048).withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HUD Header (Chat title + minimize button)
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF232538))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chats · #$activeChannelName',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Minimizar Chat',
                      child: InkWell(
                        onTap: () => setState(() => _isChatVisible = false),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.arrowUpRight,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Channel Tag / Filter Pills Row (Real channels)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: displayChannels.map((c) {
                    final isSelected =
                        c.id == _activeChannel?.id ||
                        c.name == activeChannelName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildChatTagPill(
                        label: '# ${c.name}',
                        badge: c.unreadCount > 0 ? '${c.unreadCount}' : null,
                        isSelected: isSelected,
                        onTap: () {
                          if (c.id != _activeChannel?.id) {
                            _openHybridChannel(c);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 3. Real Message Stream (No mock data)
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.messageSquare,
                                size: 26,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhuma mensagem ainda',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Envie uma mensagem abaixo!',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMine =
                              msg.author == username || msg.author == 'Você';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${msg.author}: ',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _resolveAuthorColor(
                                              msg.author,
                                              true,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text: msg.content,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                          ),
                                        ),
                                        if (msg.isEdited)
                                          TextSpan(
                                            text: ' (editada)',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.white38,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMine) ...[
                                  InkWell(
                                    onTap: () => _startEditingMessage(msg),
                                    mouseCursor: SystemMouseCursors.click,
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: Icon(
                                        LucideIcons.pencil,
                                        size: 11,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        _deleteMessage(channelKey, msg.id),
                                    mouseCursor: SystemMouseCursors.click,
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: Icon(
                                        LucideIcons.trash2,
                                        size: 11,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // 4. Compact Pill Input Field
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F101A),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: const Color(0xFF2B2D42),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Mensagem em #$activeChannelName',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) =>
                              _sendMessage(channelKey, username),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _sendMessage(channelKey, username),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(9999),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.send,
                            size: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Quick Voice Control Bar inside HUD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0E16),
                  border: Border(top: BorderSide(color: Color(0xFF1E2030))),
                ),
                child: Row(
                  children: [
                    // Mic toggle
                    Tooltip(
                      message: voiceState.isMicMuted ? 'Desmutar' : 'Mutar',
                      child: InkWell(
                        onTap: () => voiceNotifier.toggleMic(),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: voiceState.isMicMuted
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            voiceState.isMicMuted
                                ? LucideIcons.micOff
                                : LucideIcons.mic,
                            size: 15,
                            color: voiceState.isMicMuted
                                ? const Color(0xFFEF4444)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Headphones toggle
                    Tooltip(
                      message: voiceState.isDeafened
                          ? 'Ativar Áudio'
                          : 'Desativar Áudio',
                      child: InkWell(
                        onTap: () => voiceNotifier.toggleDeafened(),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: voiceState.isDeafened
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LucideIcons.headphones,
                            size: 15,
                            color: voiceState.isDeafened
                                ? const Color(0xFFEF4444)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Sair Button (Red Squircle with logOut icon)
                    InkWell(
                      onTap: _leaveVoice,
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.logOut,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sair',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTagPill({
    required String label,
    String? badge,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF23305A) : const Color(0xFF141520),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF384B7E)
                : const Color(0xFF262838),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: iconColor ?? Colors.white70),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Text(
                badge,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SERVER HOME VIEW (BANNER + RESUMO + ATIVIDADES)
  // ===========================================================================
  Widget _buildServerHomeContent(
    BuildContext context,
    bool isDark,
    String username,
    List<ChannelModel> channels,
  ) {
    final memberCount = widget.server.memberCount < 1
        ? 1
        : widget.server.memberCount;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 24,
          vertical: isMobile ? 14 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            _buildServerHeroBanner(isDark, isMobile: isMobile),

            const SizedBox(height: 20),

            // Activity + Media Listening Section
            if (isMobile) ...[
              _buildActivityCard(isDark, channels, isMobile: true),
              const SizedBox(height: 16),
              _buildMediaListeningCard(isDark),
              const SizedBox(height: 16),
              _buildCommunitySummaryCard(isDark, memberCount),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildActivityCard(
                      isDark,
                      channels,
                      isMobile: false,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildMediaListeningCard(isDark),
                        const SizedBox(height: 16),
                        _buildCommunitySummaryCard(isDark, memberCount),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Announcements and Server Details
            _buildAnnouncementsAndRulesSection(isDark, isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  // Server Hero Banner
  Widget _buildServerHeroBanner(bool isDark, {bool isMobile = false}) {
    final currentGradient = _bannerPresets[_selectedBannerPreset];
    final memberCount = widget.server.memberCount < 1
        ? 1
        : widget.server.memberCount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedAccentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedAccentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Top
          Container(
            height: isMobile ? 120 : 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(15),
                bottom: _isCustomizingBanner
                    ? Radius.zero
                    : const Radius.circular(15),
              ),
              gradient: LinearGradient(
                colors: currentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    LucideIcons.gamepad2,
                    size: isMobile ? 90 : 130,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Server Avatar
                      Container(
                        width: isMobile ? 46 : 60,
                        height: isMobile ? 46 : 60,
                        decoration: BoxDecoration(
                          color: _selectedAccentColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.gamepad2,
                            size: isMobile ? 22 : 30,
                            color: _selectedAccentColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Server Name & Category
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.server.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.server.category} · $memberCount ${memberCount == 1 ? "membro" : "membros"}',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Personalizar Button
                      if (isMobile)
                        IconButton(
                          onPressed: () => setState(
                            () => _isCustomizingBanner = !_isCustomizingBanner,
                          ),
                          icon: Icon(
                            _isCustomizingBanner
                                ? LucideIcons.x
                                : LucideIcons.slidersHorizontal,
                            size: 16,
                            color: Colors.white,
                          ),
                          tooltip: _isCustomizingBanner
                              ? 'Fechar'
                              : 'Personalizar',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF181926,
                            ).withValues(alpha: 0.85),
                            padding: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => setState(
                            () => _isCustomizingBanner = !_isCustomizingBanner,
                          ),
                          icon: Icon(
                            _isCustomizingBanner
                                ? LucideIcons.x
                                : LucideIcons.slidersHorizontal,
                            size: 14,
                          ),
                          label: Text(
                            _isCustomizingBanner ? 'Fechar' : 'Personalizar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF181926,
                            ).withValues(alpha: 0.85),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customization Drawer
          if (_isCustomizingBanner)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF141520),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Banner',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...List.generate(_bannerPresets.length, (idx) {
                      final preset = _bannerPresets[idx];
                      final isSelected = _selectedBannerPreset == idx;
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedBannerPreset = idx),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 30,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: preset,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(width: 14),
                    Text(
                      'Cor',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ..._accentPalette.map((color) {
                      final isSelected =
                          _selectedAccentColor.toARGB32() == color.toARGB32();
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedAccentColor = color),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(width: 14),

                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(serversControllerProvider.notifier)
                            .updateServerCustomization(
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
                                'Personalização salva!',
                                style: TextStyle(
                                  color:
                                      _selectedAccentColor.computeLuminance() >
                                          0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAccentColor,
                        foregroundColor:
                            _selectedAccentColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Activity Card
  Widget _buildActivityCard(bool isDark, List<ChannelModel> channels, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acontecendo no servidor',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isMobile ? 14.5 : 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Novidades recentes da comunidade',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (channels.isNotEmpty)
                ElevatedButton(
                  onPressed: () => _openHybridChannel(channels.first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAccentColor,
                    foregroundColor:
                        _selectedAccentColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 14,
                      vertical: isMobile ? 6 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          _buildActivityItem(
            isDark: isDark,
            icon: LucideIcons.bell,
            title: 'Boas-vindas ao servidor ${widget.server.name}!',
            subtitle: 'Comunidade pronta · Canais híbridos integrados',
            time: 'Hoje',
          ),
          const SizedBox(height: 10),
          _buildActivityItem(
            isDark: isDark,
            icon: LucideIcons.headphones,
            title:
                'Canal #${channels.isNotEmpty ? channels.first.name : "geral"} pronto',
            subtitle: _isTransmitting
                ? 'Transmissão de tela ativa no canal'
                : 'Conecte-se para conversar por texto, voz ou transmitir sua tela',
            time: _isTransmitting ? 'Ao Vivo' : 'Ativo',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161724) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _selectedAccentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaListeningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10281C) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.radio, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CANAL HÍBRIDO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF10B981),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _isTransmitting
                        ? LucideIcons.screenShare
                        : LucideIcons.headphones,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTransmitting
                          ? 'Transmissão Ativa'
                          : 'Sala de Áudio e Texto',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _isTransmitting
                          ? 'Transmissão de tela ao vivo'
                          : 'Pronto para conversas e transmissões',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySummaryCard(bool isDark, int memberCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da comunidade',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$memberCount',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _selectedAccentColor,
                      ),
                    ),
                    Text(
                      memberCount == 1 ? 'membro' : 'membros',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _voiceParticipants.values
                          .fold<int>(
                            0,
                            (sum, m) =>
                                sum + m.values.where((p) => p.isInVoice).length,
                          )
                          .toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'em chamada',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsAndRulesSection(bool isDark, {bool isMobile = false}) {
    final rulesWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1D2C) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.pin,
                size: 14,
                color: Color(0xFFF87171),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Regras do Servidor',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Respeite todos os membros da comunidade. Sem spam e com foco em colaboração e respeito mútuo.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );

    final hybridInfoWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1D2C) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 14,
                color: _selectedAccentColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Canais Híbridos',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cada canal combina chat de texto, chamada de áudio e transmissão de tela no mesmo ambiente integrado.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações do servidor',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (isMobile) ...[
          rulesWidget,
          const SizedBox(height: 12),
          hybridInfoWidget,
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: rulesWidget),
              const SizedBox(width: 14),
              Expanded(child: hybridInfoWidget),
            ],
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 4. RIGHT SIDEBAR (CANAIS | MEMBROS | RESUMO)
  // ===========================================================================
  Widget _buildRightSidebar(
    BuildContext context,
    bool isDark,
    List<ChannelModel> channels,
    String username,
    VoiceState voiceState,
    VoiceStateNotifier voiceNotifier,
  ) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFFAF9F6),
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF202234) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header Tabs: Canais | Membros | Resumo + Collapse Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF202234)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildSidebarTabButton(
                  title: 'Canais',
                  tab: ServerSidebarTab.canais,
                  icon: LucideIcons.volume2,
                  isDark: isDark,
                ),
                _buildSidebarTabButton(
                  title: 'Membros',
                  tab: ServerSidebarTab.membros,
                  icon: LucideIcons.users,
                  isDark: isDark,
                ),
                _buildSidebarTabButton(
                  title: 'Resumo',
                  tab: ServerSidebarTab.resumo,
                  icon: LucideIcons.barChart2,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(child: _buildSidebarTabContent(isDark, channels, username)),

          // Bottom Voice Connection Status (Docked Footer)
          _buildDockedVoiceFooter(isDark, voiceState, voiceNotifier),
        ],
      ),
    );
  }

  Widget _buildSidebarTabButton({
    required String title,
    required ServerSidebarTab tab,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _activeSidebarTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeSidebarTab = tab),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF25283E) : const Color(0xFFE2E8F0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? (isDark ? _selectedAccentColor : const Color(0xFF0F172A))
                    : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF0F172A))
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarTabContent(
    bool isDark,
    List<ChannelModel> channels,
    String username,
  ) {
    final activeCh =
        _activeChannel ?? (channels.isNotEmpty ? channels.first : null);
    final otherChannels = activeCh != null
        ? channels.where((c) => c.id != activeCh.id).toList()
        : channels;

    switch (_activeSidebarTab) {
      case ServerSidebarTab.canais:
        final activeParticipants = activeCh != null
            ? _getChannelVoiceParticipants(activeCh.id)
            : <_VoiceParticipantInfo>[];
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          children: [
            // 1. Active Channel Highlighted Card
            if (activeCh != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2034)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF333758)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel Header
                    InkWell(
                      onTap: () => _openHybridChannel(activeCh),
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.volume2,
                              size: 15,
                              color: Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeCh.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (activeParticipants.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF14532D,
                                  ).withValues(alpha: isDark ? 0.6 : 0.15),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  activeParticipants.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Real Connected Participants list
                    if (activeParticipants.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 10,
                          bottom: 8,
                        ),
                        child: Column(
                          children: activeParticipants.map((p) {
                            final isMe = p.sessionId == _clientSessionId;
                            final devLabel = p.device == 'mobile'
                                ? ' (Celular)'
                                : p.device == 'desktop'
                                    ? ' (Desktop)'
                                    : '';
                            final displayName =
                                '${p.username}$devLabel${isMe ? " (Você)" : ""}';
                            return InkWell(
                              onTap: () {
                                if (p.isTransmitting && !isMe) {
                                  setState(() {
                                    _watchingRemoteStream = p;
                                    _isChatVisible = false;
                                    _isRightSidebarVisible = false;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: _buildNestedMemberRow(
                                initials: _getAuthorInitials(p.username),
                                name: displayName,
                                color: _resolveAuthorColor(p.username, isDark),
                                isLive: p.isTransmitting,
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

            // 2. Real Other Channels from Server
            ...otherChannels.map((c) {
              final chParticipants = _getChannelVoiceParticipants(c.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _openHybridChannel(c),
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              chParticipants.isNotEmpty
                                  ? LucideIcons.volume2
                                  : LucideIcons.hash,
                              size: 14,
                              color: chParticipants.isNotEmpty
                                  ? const Color(0xFF22C55E)
                                  : (isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            if (chParticipants.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14532D)
                                      .withValues(alpha: isDark ? 0.6 : 0.15),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  chParticipants.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (chParticipants.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 10,
                          bottom: 4,
                        ),
                        child: Column(
                          children: chParticipants.map((p) {
                            final isMe = p.sessionId == _clientSessionId;
                            final devLabel = p.device == 'mobile'
                                ? ' (Celular)'
                                : p.device == 'desktop'
                                    ? ' (Desktop)'
                                    : '';
                            return InkWell(
                              onTap: () {
                                if (p.isTransmitting && !isMe) {
                                  _openHybridChannel(c);
                                  setState(() {
                                    _watchingRemoteStream = p;
                                    _isChatVisible = false;
                                    _isRightSidebarVisible = false;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: _buildNestedMemberRow(
                                initials: _getAuthorInitials(p.username),
                                name:
                                    '${p.username}$devLabel${isMe ? " (Você)" : ""}',
                                color: _resolveAuthorColor(p.username, isDark),
                                isLive: p.isTransmitting,
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );

      case ServerSidebarTab.membros:
        final membersList = _serverMembers.isNotEmpty
            ? _serverMembers
            : [
                {
                  'user': {'username': username.isNotEmpty ? username : 'Você'},
                  'role': 'owner',
                },
              ];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          children: [
            // Quick Invite Button
            InkWell(
              onTap: () => InviteMemberDialog.show(
                context,
                widget.server,
                onMembersUpdated: _loadServerMembers,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedAccentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedAccentColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.userPlus,
                      size: 14,
                      color: _selectedAccentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Convidar Pessoas',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'MEMBROS — ${membersList.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ),

            ...membersList.map((m) {
              final user = m['user'] as Map<String, dynamic>? ?? {};
              final uName = user['username'] ?? username;
              final role = m['role'] ?? 'member';
              final isOwner = role == 'owner';

              return _buildSidebarMemberRow(
                uName.toString(),
                isOwner ? '👑 Dono & Criador' : 'Membro',
                isOwner
                    ? _selectedAccentColor
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                isDark,
              );
            }),
          ],
        );

      case ServerSidebarTab.resumo:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estatísticas do Canal',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '• Canais Híbridos: ${channels.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Membros em Chamada: ${_voiceParticipants.values.fold<int>(0, (sum, m) => sum + m.values.where((p) => p.isInVoice).length)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Transmissão: ${_voiceParticipants.values.expand((m) => m.values).any((p) => p.isInVoice && p.isTransmitting) ? "Ao Vivo (Transmitindo tela)" : "Inativa"}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNestedMemberRow({
    required String initials,
    required String name,
    required Color color,
    required bool isLive,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AO VIVO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Color(0xFFC084FC),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarMemberRow(
    String name,
    String role,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Docked Voice Footer at bottom right of sidebar
  Widget _buildDockedVoiceFooter(
    bool isDark,
    VoiceState voiceState,
    VoiceStateNotifier voiceNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF202234) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.65),
                      blurRadius: 7,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Conectado',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const Spacer(),
              Text(
                'Conexão estável',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF10B981).withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_connectedVoiceChannelId != null && _activeChannel != null ? _activeChannel!.name : "geral"} · ${widget.server.name}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Tooltip(
                message: voiceState.isMicMuted
                    ? 'Desmutar Microfone'
                    : 'Mutar Microfone',
                child: InkWell(
                  onTap: () => voiceNotifier.toggleMic(),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: voiceState.isMicMuted
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : (isDark
                                ? const Color(0xFF1E2030)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: isDark
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Icon(
                        voiceState.isMicMuted
                            ? LucideIcons.micOff
                            : LucideIcons.mic,
                        size: 16,
                        color: voiceState.isMicMuted
                            ? const Color(0xFFEF4444)
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: voiceState.isDeafened
                    ? 'Ativar Áudio'
                    : 'Desativar Áudio',
                child: InkWell(
                  onTap: () => voiceNotifier.toggleDeafened(),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: voiceState.isDeafened
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : (isDark
                                ? const Color(0xFF1E2030)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: isDark
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.headphones,
                        size: 16,
                        color: voiceState.isDeafened
                            ? const Color(0xFFEF4444)
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _leaveVoice,
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Sair',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String author;
  final Color authorColor;
  final String content;
  final bool isEdited;
  final DateTime? timestamp;

  const _ChatMessage({
    required this.id,
    required this.author,
    required this.authorColor,
    required this.content,
    this.isEdited = false,
    this.timestamp,
  });

  _ChatMessage copyWith({
    String? id,
    String? author,
    Color? authorColor,
    String? content,
    bool? isEdited,
    DateTime? timestamp,
  }) {
    return _ChatMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      authorColor: authorColor ?? this.authorColor,
      content: content ?? this.content,
      isEdited: isEdited ?? this.isEdited,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'authorColor': authorColor.toARGB32(),
    'content': content,
    'is_edited': isEdited,
    'timestamp': timestamp?.toIso8601String(),
  };

    factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
    id:
        json['id'] as String? ??
        'msg_${json['timestamp'] ?? DateTime.now().microsecondsSinceEpoch}',
    author: json['author'] as String? ?? 'Usuário',
    authorColor: Color(json['authorColor'] as int? ?? 0xFFF5CBA7),
    content: json['content'] as String? ?? '',
    isEdited: json['is_edited'] as bool? ?? false,
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String)
        : null,
  );

  factory _ChatMessage.fromApi(Map<String, dynamic> m, Color defaultColor) {
    var authorName = 'Usuário';
    if (m['author'] is Map) {
      authorName = m['author']['username']?.toString() ?? 'Usuário';
    } else if (m['author_name'] != null && m['author_name'].toString().isNotEmpty) {
      authorName = m['author_name'].toString();
    } else if (m['author'] != null && m['author'].toString().isNotEmpty) {
      authorName = m['author'].toString();
    } else if (m['author_id'] != null && m['author_id'].toString().isNotEmpty) {
      authorName = m['author_id'].toString();
    }

    return _ChatMessage(
      id: (m['id'] ?? 'msg_${DateTime.now().microsecondsSinceEpoch}').toString(),
      author: authorName,
      authorColor: defaultColor,
      content: (m['content'] ?? '').toString(),
      isEdited: m['is_edited'] == true,
      timestamp: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString())
          : (m['timestamp'] != null
              ? DateTime.tryParse(m['timestamp'].toString())
              : null),
    );
  }
}

// Custom Painter for Immersive Simulation/Racing Video Stage
class _RacingStreamCanvasPainter extends CustomPainter {
  const _RacingStreamCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Asphalt Track Simulation
    final trackPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trackPaint);

    // Speed Motion Lines
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.12)
      ..strokeWidth = 2;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, size.height * 0.4),
        Offset(i + 120, size.height * 0.9),
        linePaint,
      );
    }

    // Racing Kerb Red-White Strip
    final kerbPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.72, size.width, 16),
        const Radius.circular(4),
      ),
      kerbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
