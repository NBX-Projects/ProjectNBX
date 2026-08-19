import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/server_model.dart';
import '../providers/server_provider.dart';
import '../../voice/providers/voice_provider.dart';

class HomeDashboardView extends ConsumerWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final serverNotifier = ref.read(serverProvider.notifier);
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    final selectedFilter = serverState.selectedCategoryFilter;
    final filteredServers = serverState.servers.where((server) {
      if (selectedFilter == 'ALL') return true;
      if (selectedFilter == 'FAVORITES') return server.isFavorite;
      return server.category.toUpperCase() == selectedFilter.toUpperCase();
    }).toList();

    final heroServer = serverState.servers.firstWhere(
      (s) => s.id == 'nbx-devs',
      orElse: () => serverState.servers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.bgOnyx,
      body: Stack(
        children: [
          // Background ambient gradient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.08),
                    blurRadius: 150,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonViolet.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonViolet.withValues(alpha: 0.08),
                    blurRadius: 140,
                    spreadRadius: 70,
                  ),
                ],
              ),
            ),
          ),

          // Main Scrollable Dashboard Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Dashboard Welcome & Quick Filters Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 14,
                        spacing: 16,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonCyan.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.sparkles, size: 12, color: AppColors.neonCyan),
                                        SizedBox(width: 6),
                                        Text(
                                          'NEXT-GEN SPATIAL HUBS',
                                          style: TextStyle(
                                            color: AppColors.neonCyan,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${serverState.servers.length} HUBS ATIVOS',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Community Hubs Overview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),

                          // Category Filter Pills
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FilterChip(
                                label: 'All Hubs',
                                icon: LucideIcons.layoutGrid,
                                isSelected: selectedFilter == 'ALL',
                                onTap: () => serverNotifier.setCategoryFilter('ALL'),
                              ),
                              _FilterChip(
                                label: 'Dev & Engineering',
                                icon: LucideIcons.code,
                                isSelected: selectedFilter == 'DEV',
                                onTap: () => serverNotifier.setCategoryFilter('DEV'),
                              ),
                              _FilterChip(
                                label: 'Gaming',
                                icon: LucideIcons.gamepad2,
                                isSelected: selectedFilter == 'GAMING',
                                onTap: () => serverNotifier.setCategoryFilter('GAMING'),
                              ),
                              _FilterChip(
                                label: 'AI & Synth',
                                icon: LucideIcons.cpu,
                                isSelected: selectedFilter == 'AI',
                                onTap: () => serverNotifier.setCategoryFilter('AI'),
                              ),
                              _FilterChip(
                                label: 'Favorites',
                                icon: LucideIcons.star,
                                isSelected: selectedFilter == 'FAVORITES',
                                onTap: () => serverNotifier.setCategoryFilter('FAVORITES'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderSubtle),

                    ],
                  ),
                ),
              ),

              // Dynamic Bento Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 950;
                      return Column(
                        children: [
                          // Top Bento Row: Hero Bento Card (2/3 width) + Live Voice Bento Card (1/3 width)
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _HeroBentoCard(
                                    server: heroServer,
                                    onEnter: () => serverNotifier.selectServer(heroServer),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 4,
                                  child: _LiveVoiceBentoCard(
                                    voiceState: voiceState,
                                    onJoinLounge: () {
                                      voiceNotifier.joinVoiceChannel('nbx-live-showcase', '🔊 live-showcase');
                                      serverNotifier.selectServer(heroServer);
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _HeroBentoCard(
                                  server: heroServer,
                                  onEnter: () => serverNotifier.selectServer(heroServer),
                                ),
                                const SizedBox(height: 18),
                                _LiveVoiceBentoCard(
                                  voiceState: voiceState,
                                  onJoinLounge: () {
                                    voiceNotifier.joinVoiceChannel('nbx-live-showcase', '🔊 live-showcase');
                                    serverNotifier.selectServer(heroServer);
                                  },
                                ),
                              ],
                            ),

                          const SizedBox(height: 18),

                          // Secondary Bento Row: Multi-Hub Bento Cards Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredServers.where((s) => s.id != heroServer.id || !isWide).length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 3 : (constraints.maxWidth > 650 ? 2 : 1),
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: isWide ? 1.25 : 1.15,
                            ),
                            itemBuilder: (context, index) {
                              final list = filteredServers.where((s) => s.id != heroServer.id || !isWide).toList();
                              final s = list[index];
                              return _StandardBentoCard(
                                server: s,
                                onTap: () => serverNotifier.selectServer(s),
                              );
                            },
                          ),

                          const SizedBox(height: 100), // Padding for floating CTA
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Floating Quick-Join Action Button
          Positioned(
            bottom: 24,
            right: 28,
            child: _FloatingQuickJoinButton(
              onTap: () {
                voiceNotifier.joinVoiceChannel('nbx-live-showcase', '🔊 live-showcase');
                serverNotifier.selectServer(heroServer);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonCyan.withValues(alpha: 0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.neonCyan : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyanGlow.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.neonCyan : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBentoCard extends StatelessWidget {
  final Server server;
  final VoidCallback onEnter;

  const _HeroBentoCard({
    required this.server,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEnter,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 290,
        decoration: BoxDecoration(
          gradient: server.bannerGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyanGlow.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Cyber glow patterns
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                LucideIcons.terminal,
                size: 200,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),

            // Top Badges & Live Status
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.neonEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'TOP ACTIVE HUB',
                          style: TextStyle(
                            color: AppColors.neonCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (server.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonCoral,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: AppColors.coralGlow, blurRadius: 8),
                        ],
                      ),
                      child: Text(
                        '${server.unreadCount} NEW UPDATES',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Main Content Area
            Positioned(
              left: 24,
              bottom: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.cyanVioletGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: AppColors.cyanGlow, blurRadius: 10),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          server.acronym,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              server.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Active Stats Bar & Enter Button
                  Row(
                    children: [
                      _StatCapsule(
                        icon: LucideIcons.users,
                        label: '${server.onlineCount} online',
                        color: AppColors.neonEmerald,
                      ),
                      const SizedBox(width: 10),
                      if (server.activeVoiceTopic != null)
                        _StatCapsule(
                          icon: LucideIcons.audioWaveform,
                          label: '${server.activeVoiceMembers.length} in ${server.activeVoiceTopic}',
                          color: AppColors.neonCyan,
                        ),
                      const Spacer(),

                      // Action Button
                      ElevatedButton.icon(
                        onPressed: onEnter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          shadowColor: AppColors.neonCyan.withValues(alpha: 0.5),
                        ),
                        icon: const Icon(LucideIcons.arrowRight, size: 16),
                        label: const Text(
                          'ENTER HUB',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveVoiceBentoCard extends StatelessWidget {
  final dynamic voiceState;
  final VoidCallback onJoinLounge;

  const _LiveVoiceBentoCard({
    required this.voiceState,
    required this.onJoinLounge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonViolet.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetGlow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonViolet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.radio, color: AppColors.neonViolet, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE AUDIO MESH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Opus 48kHz • 14ms WebRTC SFU',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.neonEmerald,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Active Voice Participants Capsule preview
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active in #live-showcase',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AvatarPill(tag: 'TL', isSpeaking: false),
                      const SizedBox(width: 8),
                      _AvatarPill(tag: 'LD', isSpeaking: true),
                      const SizedBox(width: 8),
                      _AvatarPill(tag: 'GB', isSpeaking: false),
                      const SizedBox(width: 8),
                      _AvatarPill(tag: 'AI', isSpeaking: false),
                    ],
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Telemetry:',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      Text(
                        '0% Packet Loss • 60 FPS Stream',
                        style: TextStyle(color: AppColors.neonEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // One-Click Join Audio CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onJoinLounge,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(LucideIcons.headphones, size: 16),
              label: const Text(
                'ONE-CLICK JOIN AUDIO',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardBentoCard extends StatelessWidget {
  final Server server;
  final VoidCallback onTap;

  const _StandardBentoCard({
    required this.server,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Acronym Avatar + Category + Unread Badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: server.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: server.accentColor.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    server.acronym,
                    style: TextStyle(
                      color: server.accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${server.memberCount} members',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (server.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.neonCoral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${server.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Expanded(
              child: Text(
                server.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 10),

            // Tags Row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: server.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Footer: Online members & Voice preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.neonEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${server.onlineCount} online',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                if (server.activeVoiceTopic != null)
                  Row(
                    children: [
                      const Icon(LucideIcons.audioWaveform, size: 12, color: AppColors.neonCyan),
                      const SizedBox(width: 4),
                      Text(
                        '${server.activeVoiceMembers.length} on voice',
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCapsule extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatCapsule({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPill extends StatelessWidget {
  final String tag;
  final bool isSpeaking;

  const _AvatarPill({
    required this.tag,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.cyanVioletGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSpeaking ? AppColors.neonEmerald : Colors.transparent,
          width: isSpeaking ? 2 : 1,
        ),
        boxShadow: isSpeaking
            ? [
                const BoxShadow(color: AppColors.emeraldGlow, blurRadius: 8),
              ]
            : [],
      ),
      alignment: Alignment.center,
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FloatingQuickJoinButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingQuickJoinButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.cyanVioletGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.zap, color: Colors.black, size: 18),
            SizedBox(width: 10),
            Text(
              'QUICK JOIN ACTIVE SQUAD',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
