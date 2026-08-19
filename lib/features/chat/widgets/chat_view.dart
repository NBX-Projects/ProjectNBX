import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../servers/providers/server_provider.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSend() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    ref.read(serverProvider.notifier).sendMessage(text);
    _controller.clear();

    // Scroll to bottom
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
      color: AppColors.bgChat,
      child: Column(
        children: [
          // Channel Top Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.hash, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  selectedChannel.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 12),
                const VerticalDivider(color: AppColors.divider, width: 1, indent: 12, endIndent: 12),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Canal oficial da comunidade NBX Developers',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.bell, color: AppColors.textInteractive, size: 18),
                  tooltip: 'Notificações',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(LucideIcons.pin, color: AppColors.textInteractive, size: 18),
                  tooltip: 'Mensagens Fixadas',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(LucideIcons.users, color: AppColors.textInteractive, size: 18),
                  tooltip: 'Membros',
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.messageSquare, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Bem-vindo ao início do #${selectedChannel.name}!',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Este é o início da sua conversa.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _ChatMessageTile(message: msg);
                    },
                  ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.circlePlus, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Enviar Arquivo',
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _handleSend(),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Conversar em #${selectedChannel.name}',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.smile, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Emojis',
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.send, color: AppColors.primary, size: 18),
                    tooltip: 'Enviar Mensagem',
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

class _ChatMessageTile extends StatelessWidget {
  final dynamic message;
  const _ChatMessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: message.isCurrentUser ? AppColors.primary : AppColors.bgCard,
              borderRadius: BorderRadius.circular(19),
            ),
            alignment: Alignment.center,
            child: Text(
              message.authorAvatar,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
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
                      message.authorName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: AppColors.textInteractive,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
