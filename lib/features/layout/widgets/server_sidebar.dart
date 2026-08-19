import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../servers/providers/server_provider.dart';

class ServerSidebar extends ConsumerWidget {
  const ServerSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final selectedServer = serverState.selectedServer;

    return Container(
      width: 72,
      color: AppColors.bgServerSidebar,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Home / App Logo Icon
          _ServerIconItem(
            tooltip: 'ProjectNBX Home',
            isActive: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  LucideIcons.radio,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            onTap: () {
              // Direct message / Home action
            },
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(color: AppColors.divider, height: 2),
          ),
          const SizedBox(height: 8),

          // Servers List
          Expanded(
            child: ListView.builder(
              itemCount: serverState.servers.length,
              itemBuilder: (context, index) {
                final server = serverState.servers[index];
                final isSelected = selectedServer.id == server.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ServerIconItem(
                    tooltip: server.name,
                    isActive: isSelected,
                    onTap: () => ref.read(serverProvider.notifier).selectServer(server),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        server.acronym,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textInteractive,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Add Server Button
          _ServerIconItem(
            tooltip: 'Adicionar Servidor',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Criar ou Entrar em Servidor em breve!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                LucideIcons.plus,
                color: AppColors.speakingGreen,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ServerIconItem extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerIconItem({
    required this.child,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Active pill indicator
              Positioned(
                left: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 4,
                  height: isActive ? 40 : 0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
