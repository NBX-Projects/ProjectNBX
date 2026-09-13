import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../servers/models/ux_nbx_data.dart';
import '../../servers/models/ux_nbx_models.dart';

class TheaterMode extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleDeafen;
  final bool isMuted;
  final bool isDeafened;
  final Function(String message)? onSendMessage;

  const TheaterMode({
    super.key,
    required this.onExit,
    this.onToggleMute,
    this.onToggleDeafen,
    this.isMuted = false,
    this.isDeafened = false,
    this.onSendMessage,
  });

  @override
  State<TheaterMode> createState() => _TheaterModeState();
}

class _TheaterModeState extends State<TheaterMode> {
  bool _showChat = false;
  bool _showParticipants = false;
  final TextEditingController _msgController = TextEditingController();
  final List<ChatMessageData> _messages = List.from(uxMessages);

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgController.text.trim();
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
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Main Video / Stream Area
          Positioned.fill(
            child: Row(
              children: [
                // Video & Participant Canvas
                Expanded(
                  child: Column(
                    children: [
                      // Top Stream Canvas
                      Expanded(
                        flex: 7,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101216),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=1600&h=900&fit=crop&auto=format',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.black87,
                                  child: const Center(
                                    child: Icon(LucideIcons.radio, color: AppColors.yellow, size: 48),
                                  ),
                                ),
                              ),
                              // Live Badge
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.radio, size: 12, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'AO VIVO • Marina_S (Le Mans)',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Top Right Close Button
                              Positioned(
                                top: 16,
                                right: 16,
                                child: InkWell(
                                  onTap: widget.onExit,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.x, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom Participants Thumbnails
                      Container(
                        height: 110,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: uxVoiceUsers.map((user) {
                            return _buildParticipantTile(user);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Side Chat Drawer
                if (_showChat)
                  Container(
                    width: 340,
                    decoration: const BoxDecoration(
                      color: AppColors.panel,
                      border: Border(left: BorderSide(color: AppColors.border)),
                    ),
                    child: _buildChatDrawer(),
                  ),

                // Side Participants Drawer
                if (_showParticipants && !_showChat)
                  Container(
                    width: 260,
                    decoration: const BoxDecoration(
                      color: AppColors.panel,
                      border: Border(left: BorderSide(color: AppColors.border)),
                    ),
                    child: _buildParticipantsDrawer(),
                  ),
              ],
            ),
          ),

          // Floating Bottom Controls Bar
          Positioned(
            bottom: 24,
            left: 0,
            right: _showChat || _showParticipants ? 340 : 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.deep.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingButton(
                      icon: widget.isMuted ? LucideIcons.micOff : LucideIcons.mic,
                      color: widget.isMuted ? AppColors.red : Colors.white,
                      tooltip: widget.isMuted ? 'Desmutar' : 'Mutar',
                      onTap: widget.onToggleMute,
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingButton(
                      icon: widget.isDeafened ? LucideIcons.volumeX : LucideIcons.headphones,
                      color: widget.isDeafened ? AppColors.red : Colors.white,
                      tooltip: widget.isDeafened ? 'Ouvir' : 'Ensurdecer',
                      onTap: widget.onToggleDeafen,
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingButton(
                      icon: LucideIcons.messageSquare,
                      color: _showChat ? AppColors.accent : Colors.white,
                      tooltip: 'Chat ao vivo',
                      onTap: () => setState(() {
                        _showChat = !_showChat;
                        if (_showChat) _showParticipants = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingButton(
                      icon: LucideIcons.users,
                      color: _showParticipants ? AppColors.accent : Colors.white,
                      tooltip: 'Participantes',
                      onTap: () => setState(() {
                        _showParticipants = !_showParticipants;
                        if (_showParticipants) _showChat = false;
                      }),
                    ),
                    const SizedBox(width: 12),
                    // Disconnect button
                    ElevatedButton.icon(
                      onPressed: widget.onExit,
                      icon: const Icon(LucideIcons.phoneOff, size: 14, color: Colors.white),
                      label: const Text('Sair', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(VoiceUserData user) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: user.speaking ? AppColors.green : AppColors.border,
          width: user.speaking ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: user.color.withValues(alpha: 0.2),
            child: Text(
              user.initials,
              style: TextStyle(color: user.color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.muted) ...[
                const Icon(LucideIcons.micOff, size: 11, color: AppColors.red),
                const SizedBox(width: 4),
              ],
              Text(
                user.name,
                style: const TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildChatDrawer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.hash, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              const Text('Chat da Transmissão', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showChat = false),
                icon: const Icon(LucideIcons.x, size: 16, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(msg.author, style: TextStyle(color: msg.color, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Text(msg.time, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(msg.content, style: const TextStyle(color: AppColors.text, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.deep,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Enviar mensagem...',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _send,
                icon: const Icon(LucideIcons.send, size: 16, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsDrawer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.users, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              const Text('Em Chamada (4)', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showParticipants = false),
                icon: const Icon(LucideIcons.x, size: 16, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: uxVoiceUsers.length,
            itemBuilder: (context, index) {
              final user = uxVoiceUsers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.deep,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: user.speaking ? AppColors.green : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: user.color.withValues(alpha: 0.2),
                      child: Text(user.initials, style: TextStyle(color: user.color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(user.name, style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    if (user.speaking)
                      const Icon(LucideIcons.volume2, size: 14, color: AppColors.green),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
