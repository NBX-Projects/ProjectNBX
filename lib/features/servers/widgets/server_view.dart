import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  String _selectedChannelId = "t1";
  String _activeTab = "channels"; // channels, members, board
  bool _showTheater = false;
  bool _showMembers = true;
  String? _currentFileFolder = "root";
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessageData> _messages = List.from(uxMessages);

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessageData(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          author: 'Você',
          initials: 'EU',
          color: AppColors.accent,
          time: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          content: text,
          isMe: true,
        ),
      );
    });
    widget.onSendMessage?.call(text);
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final server = uxServers.firstWhere(
      (s) => s.id == widget.serverId,
      orElse: () => uxServers.first,
    );

    final selectedChannel = uxChannels.firstWhere(
      (c) => c.id == _selectedChannelId,
      orElse: () => uxChannels.first,
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
          // Add Server
          Tooltip(
            message: 'Adicionar Servidor',
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(LucideIcons.plus, color: AppColors.green, size: 20),
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
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: const Border(top: BorderSide(color: AppColors.border)),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('CANAIS DE TEXTO & VOZ', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        ...uxChannels.map((channel) {
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
                          if (msg.reactions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: msg.reactions.entries.map((entry) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.panel,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(entry.key, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text('${entry.value}', style: const TextStyle(color: AppColors.dim, fontSize: 11)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
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
                      hintText: 'Conversar em #geral...',
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
