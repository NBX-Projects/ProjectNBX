import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../servers/providers/server_provider.dart';
import '../servers/widgets/home_dashboard_view.dart';
import '../servers/widgets/unified_hub_view.dart';
import 'widgets/top_command_bar.dart';
import 'widgets/command_palette_modal.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final serverNotifier = ref.read(serverProvider.notifier);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          serverNotifier.toggleCommandPalette();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          serverNotifier.toggleCommandPalette();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (serverState.showCommandPalette) {
            serverNotifier.toggleCommandPalette(false);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.bgOnyx,
          body: Stack(
            children: [
              Column(
                children: [
                  // 1. Top Navigation Bar (Cmd+K search, DMs, user avatar, status)
                  const TopCommandBar(),

                  // 2. Main Center Workspace
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: serverState.viewMode == ViewMode.homeDashboard
                          ? const HomeDashboardView(key: ValueKey('HomeDashboard'))
                          : const UnifiedHubView(key: ValueKey('UnifiedHubView')),
                    ),
                  ),
                ],
              ),

              // 3. Command Palette Modal Overlay (Cmd+K)
              if (serverState.showCommandPalette)
                const Positioned.fill(
                  child: CommandPaletteModal(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
