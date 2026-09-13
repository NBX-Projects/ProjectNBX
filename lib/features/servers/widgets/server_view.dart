import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../voice/widgets/theater_mode.dart';
import '../models/ux_nbx_data.dart';
import '../models/ux_nbx_models.dart';

class ServerView extends StatefulWidget {
  final String serverId;
  final VoidCallback onBack;
  final Function(String id) onSwitchServer;
  final Function(Map<String, dynamic>? call)? onCallChange;
  final Function(String message)? onSendMessage;
  final bool isMuted;
  final bool isDeafened;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleDeafen;
  final VoidCallback? onDisconnectCall;

  const ServerView({
    super.key,
    required this.serverId,
    required this.onBack,
    required this.onSwitchServer,
    this.onCallChange,
    this.onSendMessage,
    this.isMuted = false,
    this.isDeafened = false,
    this.onToggleMute,
    this.onToggleDeafen,
    this.onDisconnectCall,
  });

  @override
  State<ServerView> createState() => _ServerViewState();
}

class _ServerViewState extends State<ServerView> {
  final ApiClient _apiClient = ApiClient();
  final WebSocketClient _wsClient = WebSocketClient();
  StreamSubscription? _wsSub;

  String _selectedChannelId = "t1";
  String _activeTab = "channels"; // channels, members, board
  bool _showTheater = false;
  bool _showMembers = true;
  String? _currentFileFolder = "root";
  final TextEditingController _chatController = TextEditingController();

  List<ChannelData> _channels = List.from(uxChannels);
  List<ChatMessageData> _messages = List.from(uxMessages);

  @override
  void initState() {
    super.initState();
    _loadLiveChannels();
    _loadLiveMessages();
    _initWebSocket();
  }

  @override
  void didUpdateWidget(covariant ServerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverId != widget.serverId) {
      _loadLiveChannels();
      _loadLiveMessages();
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsClient.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _initWebSocket() {
    _wsClient.connect(serverId: widget.serverId);
    _wsSub = _wsClient.events.listen((event) {
      if (event['type'] == 'CHAT_MESSAGE') {
        final payload = event['payload'];
        if (payload is Map<String, dynamic>) {
          final chId = event['channel_id'] as String? ?? _selectedChannelId;
          if (chId == _selectedChannelId) {
            final authorMap = payload['author'] as Map<String, dynamic>?;
            final authorName = authorMap?['username'] as String? ?? 'Dev';
            final authorId = payload['author_id'] as String? ?? '';

            if (authorId == 'usr_dev_1' || authorName.contains('Você')) {
              return; // Já renderizado localmente de forma instantânea
            }

            if (mounted) {
              setState(() {
                _messages.add(
                  ChatMessageData(
                    id: payload['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
                    author: authorName,
                    initials: authorName.length >= 2 ? authorName.substring(0, 2).toUpperCase() : 'NB',
                    color: AppColors.accent,
                    time: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    content: payload['content'] as String? ?? '',
                    isMe: false,
                  ),
                );
              });
            }
          }
        }
      }
    });
  }

  Future<void> _loadLiveChannels() async {
    try {
      final liveList = await _apiClient.listChannels(widget.serverId);
      if (liveList.isNotEmpty && mounted) {
        setState(() {
          _channels = liveList.map((ch) {
            final id = ch['id']?.toString() ?? 't1';
            final name = ch['name']?.toString() ?? 'geral';
            final typeStr = ch['type']?.toString() ?? 'text';
            ChannelKind kind = ChannelKind.text;
            if (typeStr == 'voice' || name.toLowerCase().contains('match') || name.toLowerCase().contains('review') || name.toLowerCase().contains('stream')) {
              kind = ChannelKind.textVoice;
            } else if (name.contains('imagens')) {
              kind = ChannelKind.images;
            } else if (name.contains('arquivos')) {
              kind = ChannelKind.files;
            }

            return ChannelData(
              id: id,
              name: name,
              type: kind,
              users: kind == ChannelKind.textVoice ? uxVoiceUsers : const [],
              description: "Canal em tempo real conectado ao Go Backend",
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[ServerView] Erro ao carregar canais: $e');
    }
  }

  Future<void> _loadLiveMessages() async {
    try {
      final msgs = await _apiClient.listMessages(widget.serverId, _selectedChannelId);
      if (msgs.isNotEmpty && mounted) {
        setState(() {
          _messages = msgs.map((m) {
            final authorMap = m['author'] as Map<String, dynamic>?;
            final authorName = authorMap?['username'] as String? ?? 'DarkLord_X';
            final content = m['content']?.toString() ?? '';
            final id = m['id']?.toString() ?? '1';

            return ChatMessageData(
              id: id,
              author: authorName,
              initials: authorName.length >= 2 ? authorName.substring(0, 2).toUpperCase() : 'NB',
              color: AppColors.accent,
              time: '10:30',
              content: content,
              isMe: authorName.contains('Você'),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[ServerView] Erro ao carregar mensagens: $e');
    }
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final newMsg = ChatMessageData(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      author: 'Você',
      initials: 'EU',
      color: AppColors.accent,
      time: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      content: text,
      isMe: true,
    );

    setState(() {
      _messages.add(newMsg);
    });

    // Envia via REST para o Go backend e emite via WebSocket
    _apiClient.sendMessage(widget.serverId, _selectedChannelId, text);
    _wsClient.sendEvent(
      'CHAT_MESSAGE',
      {'content': text},
      channelId: _selectedChannelId,
      serverId: widget.serverId,
    );

    widget.onSendMessage?.call(text);
    _chatController.clear();
  }

  void _showCreateChannelDialog() {
    final controller = TextEditingController();
    String selectedType = "text";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text('Criar Canal', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.text, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Nome do canal (ex: clipes, duos)...',
                  hintStyle: TextStyle(color: AppColors.muted),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Texto (#)', style: TextStyle(fontSize: 12)),
                    selected: selectedType == "text",
                    onSelected: (val) => setDialogState(() => selectedType = "text"),
                    selectedColor: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Voz (🔊)', style: TextStyle(fontSize: 12)),
                    selected: selectedType == "voice",
                    onSelected: (val) => setDialogState(() => selectedType = "voice"),
                    selectedColor: AppColors.green,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  final res = await _apiClient.createChannel(widget.serverId, name, selectedType);
                  if (res != null) {
                    _loadLiveChannels();
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Criar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final server = uxServers.firstWhere(
      (s) => s.id == widget.serverId,
      orElse: () => uxServers.first,
    );

    final selectedChannel = _channels.firstWhere(
      (c) => c.id == _selectedChannelId,
      orElse: () => _channels.first,
    );

    if (_showTheater) {
      return TheaterMode(
        onExit: () => setState(() => _showTheater = false),
        onToggleMute: widget.onToggleMute,
        onToggleDeafen: widget.onToggleDeafen,
        isMuted: widget.isMuted,
        isDeafened: widget.isDeafened,
        onSendMessage: widget.onSendMessage,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // 1. Navigation Server Rail
          _buildServerRail(server),

          // 2. Channel & Server Sidebar
          Container(
            width: 240,
            color: AppColors.deep,
            child: _buildChannelSidebar(server),
          ),

          // 3. Center Main Workspace
          Expanded(
            child: Column(
              children: [
                // Channel Top Header
                _buildChannelHeader(selectedChannel, server),

                // Channel Body
                Expanded(
                  child: _buildChannelBody(selectedChannel),
                ),
              ],
            ),
          ),

          // 4. Right Members Sidebar
          if (_showMembers && _activeTab == "channels")
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AppColors.deep,
                border: Border(left: BorderSide(color: AppColors.border)),
              ),
              child: _buildMembersSidebar(),
            ),
        ],
      ),
    );
  }

  Widget _buildServerRail(ServerData currentServer) {
    return Container(
      width: 72,
      color: const Color(0xFF141619),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Back to Hub Button
          Tooltip(
            message: 'Voltar ao Hub',
            child: InkWell(
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.border, height: 1),
          ),
          // Server List
          Expanded(
            child: ListView.builder(
              itemCount: uxServers.length,
              itemBuilder: (context, index) {
                final s = uxServers[index];
                final isSelected = s.id == currentServer.id;
                final initials = s.name.length >= 2 ? s.name.substring(0, 2).toUpperCase() : s.name;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tooltip(
                    message: s.name,
                    child: InkWell(
                      onTap: () => widget.onSwitchServer(s.id),
                      borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? s.accentColor : AppColors.panel,
                          borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.dim,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildChannelSidebar(ServerData server) {
    return Column(
      children: [
        // Server Banner & Name Header
        Container(
          height: 110,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(server.banner),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    server.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(LucideIcons.chevronDown, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),

        // Tabs: Canais | Membros | Quadro
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _buildTabButton("Canais", "channels"),
              _buildTabButton("Membros", "members"),
              _buildTabButton("Quadro", "board"),
            ],
          ),
        ),

        // Channels List
        Expanded(
          child: _activeTab == "channels"
              ? _buildChannelsList()
              : _activeTab == "members"
                  ? _buildMembersSidebar()
                  : _buildBoardList(),
        ),

        // Active Voice Strip (if in text-voice)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.panel,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: const Text('EU', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Você', style: TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('#online', style: TextStyle(color: AppColors.green, fontSize: 10)),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onToggleMute,
                icon: Icon(widget.isMuted ? LucideIcons.micOff : LucideIcons.mic, size: 16, color: widget.isMuted ? AppColors.red : AppColors.text),
              ),
              IconButton(
                onPressed: widget.onToggleDeafen,
                icon: Icon(widget.isDeafened ? LucideIcons.volumeX : LucideIcons.headphones, size: 16, color: widget.isDeafened ? AppColors.red : AppColors.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final isSelected = _activeTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = tabKey),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.panel : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.muted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelsList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('CANAIS', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            IconButton(
              onPressed: _showCreateChannelDialog,
              icon: const Icon(LucideIcons.plus, size: 14, color: AppColors.muted),
              tooltip: 'Criar Canal',
            ),
          ],
        ),
        ..._channels.map((channel) {
          final isSelected = _selectedChannelId == channel.id;
          IconData iconData = LucideIcons.hash;
          if (channel.type == ChannelKind.textVoice) iconData = LucideIcons.volume2;
          if (channel.type == ChannelKind.images) iconData = LucideIcons.image;
          if (channel.type == ChannelKind.files) iconData = LucideIcons.folder;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _selectedChannelId = channel.id);
                  _loadLiveMessages();

                  if (channel.type == ChannelKind.textVoice) {
                    widget.onCallChange?.call({
                      'serverId': widget.serverId,
                      'serverName': 'Apex Predators',
                      'channelName': channel.name,
                    });
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.panel : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, size: 16, color: isSelected ? Colors.white : AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          channel.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.dim,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (channel.unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${channel.unread}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),
              // If text-voice, show users in channel
              if (channel.type == ChannelKind.textVoice && channel.users.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4, bottom: 6),
                  child: Column(
                    children: channel.users.map((u) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: u.color.withValues(alpha: 0.2),
                              child: Text(u.initials, style: TextStyle(color: u.color, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            Text(u.name, style: TextStyle(color: u.speaking ? AppColors.green : AppColors.dim, fontSize: 11)),
                            const Spacer(),
                            if (u.isStreaming)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(4)),
                                child: const Text('AO VIVO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildChannelHeader(ChannelData channel, ServerData server) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.hash, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Text(
            channel.name,
            style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Container(height: 16, width: 1, color: AppColors.border),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              channel.description,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Live Screen Share / Theater Trigger
          if (channel.type == ChannelKind.textVoice)
            ElevatedButton.icon(
              onPressed: () => setState(() => _showTheater = true),
              icon: const Icon(LucideIcons.radio, size: 13, color: Colors.white),
              label: const Text('Transmitir / Assistir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => setState(() => _showMembers = !_showMembers),
            icon: Icon(LucideIcons.users, size: 18, color: _showMembers ? AppColors.accent : AppColors.muted),
            tooltip: 'Lista de Membros',
          ),
        ],
      ),
    );
  }

  Widget _buildChannelBody(ChannelData channel) {
    if (channel.type == ChannelKind.images) {
      return _buildImagesGallery();
    }
    if (channel.type == ChannelKind.files) {
      return _buildFileExplorer();
    }
    return _buildChatMessages();
  }

  Widget _buildChatMessages() {
    return Column(
      children: [
        // Messages feed
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: msg.color.withValues(alpha: 0.2),
                      child: Text(
                        msg.initials,
                        style: TextStyle(color: msg.color, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                msg.author,
                                style: TextStyle(
                                  color: msg.isMe ? AppColors.accent : AppColors.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(msg.time, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(msg.content, style: const TextStyle(color: AppColors.text, fontSize: 13, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Message Input Box with formatting buttons
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.panel,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.plusCircle, color: AppColors.muted, size: 20),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.deep,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _chatController,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Conversar...',
                      hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(LucideIcons.send, color: AppColors.accent, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagesGallery() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: uxImageGallery.length,
      itemBuilder: (context, index) {
        final item = uxImageGallery[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.network(
                  item.src,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('por ${item.author}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileExplorer() {
    final items = uxFileExplorer[_currentFileFolder] ?? uxFileExplorer['root']!;

    return Column(
      children: [
        if (_currentFileFolder != 'root')
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _currentFileFolder = 'root'),
                  icon: const Icon(LucideIcons.arrowLeft, size: 14),
                  label: const Text('Voltar para raiz', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.panel),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final file = items[index];
              final isFolder = file.kind == 'folder';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFolder ? LucideIcons.folder : LucideIcons.file,
                      color: isFolder ? AppColors.yellow : AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(file.name, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${file.detail} • ${file.updated}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (isFolder)
                      ElevatedButton(
                        onPressed: () => setState(() => _currentFileFolder = file.id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.deep),
                        child: const Text('Abrir', style: TextStyle(fontSize: 11)),
                      )
                    else
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.download, size: 16, color: AppColors.dim),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoardList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: uxBoardItems.map((b) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.title, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(b.content, style: const TextStyle(color: AppColors.dim, fontSize: 12)),
              const SizedBox(height: 6),
              Text('${b.date} • ${b.author}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMembersSidebar() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('MEMBROS DO SERVIDOR (9)', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        ...uxMembers.map((m) {
          Color dotColor = AppColors.green;
          if (m.status == 'streaming') dotColor = AppColors.purple;
          if (m.status == 'idle') dotColor = AppColors.yellow;
          if (m.status == 'dnd') dotColor = AppColors.red;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: m.color.withValues(alpha: 0.2),
                      child: Text(m.initials, style: TextStyle(color: m.color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: TextStyle(color: m.roleColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      if (m.playing.isNotEmpty)
                        Text('Jogando ${m.playing}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(4)),
                  child: Text(m.role, style: TextStyle(color: m.roleColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
