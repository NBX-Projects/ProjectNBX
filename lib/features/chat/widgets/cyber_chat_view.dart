import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../servers/providers/server_provider.dart';

class CyberChatView extends ConsumerStatefulWidget {
  const CyberChatView({super.key});

  @override
  ConsumerState<CyberChatView> createState() => _CyberChatViewState();
}

class _CyberChatViewState extends ConsumerState<CyberChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSend() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    ref.read(serverProvider.notifier).sendMessage(text);
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final selectedChannel = serverState.selectedChannel;
    final messages = serverState.channelMessages[selectedChannel.id] ?? [];

    return Container(
      color: AppColors.bgOnyx,
      child: Column(
        children: [
          // Channel Title Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.terminal, color: AppColors.neonCyan, size: 18),
                const SizedBox(width: 10),
                Text(
                  selectedChannel.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 16, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'NBX Developer Stream // E2E Encrypted Channel',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _HeaderAction(icon: LucideIcons.code, tooltip: 'Compartilhar Snippet', onTap: () {}),
                _HeaderAction(icon: LucideIcons.search, tooltip: 'Pesquisar Logs', onTap: () {}),
              ],
            ),
          ),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _CyberMessageTile(message: msg);
              },
            ),
          ),

          // Cyber Input Command Deck
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderGlow),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.code2, color: AppColors.neonViolet, size: 18),
                    tooltip: 'Inserir Código',
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _handleSend(),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Transmitir mensagem em // ${selectedChannel.name}...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.paperclip, color: AppColors.textSecondary, size: 18),
                    tooltip: 'Anexar Arquivo',
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.send, color: AppColors.neonCyan, size: 18),
                    tooltip: 'Enviar (Enter)',
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: AppColors.textSecondary, size: 16),
        ),
      ),
    );
  }
}

class _CyberMessageTile extends StatelessWidget {
  final dynamic message;
  const _CyberMessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: message.isCurrentUser ? AppColors.cyanVioletGradient : null,
              color: message.isCurrentUser ? null : AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: message.isCurrentUser ? AppColors.neonCyan.withValues(alpha: 0.5) : AppColors.borderSubtle,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              message.authorAvatar,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: message.isCurrentUser ? AppColors.neonCyan.withValues(alpha: 0.2) : AppColors.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.authorName,
                        style: TextStyle(
                          color: message.isCurrentUser ? AppColors.neonCyan : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.35,
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
}
