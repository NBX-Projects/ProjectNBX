import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/ux_nbx_data.dart';
import '../models/ux_nbx_models.dart';

class HubScreen extends StatefulWidget {
  final Function(String serverId) onEnterServer;
  final Map<String, dynamic>? activeCall;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleDeafen;
  final VoidCallback? onDisconnectCall;
  final bool isMuted;
  final bool isDeafened;

  const HubScreen({
    super.key,
    required this.onEnterServer,
    this.activeCall,
    this.onToggleMute,
    this.onToggleDeafen,
    this.onDisconnectCall,
    this.isMuted = false,
    this.isDeafened = false,
  });

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  String _selectedCategory = "TODOS";
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredServers = uxServers.where((s) {
      final matchesCategory = _selectedCategory == "TODOS" ||
          s.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // 1. Navigation Server Rail
          _buildNavigationRail(),

          // 2. Main Hub Discovery Content
          Expanded(
            child: Column(
              children: [
                // Top Header with Search, Filter & Profile
                _buildTopHeader(),

                // Center Content: Discovery Grid & Right Activity Panel
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Discovery Grid
                      Expanded(
                        flex: 7,
                        child: _buildDiscoveryGrid(filteredServers),
                      ),

                      // Right Sidebar: Amigos & Atividades
                      Container(
                        width: 320,
                        decoration: const BoxDecoration(
                          color: AppColors.deep,
                          border: Border(
                            left: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: _buildRightActivityPanel(),
                      ),
                    ],
                  ),
                ),

                // Persistent Bottom Active Call Bar
                if (widget.activeCall != null) _buildActiveCallBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 72,
      color: AppColors.deep,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Discovery / Compass Icon (Active)
          _buildRailIcon(
            icon: LucideIcons.compass,
            tooltip: 'Hub Comunitário',
            isActive: true,
            accentColor: AppColors.accent,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          // Direct Messages
          _buildRailIcon(
            icon: LucideIcons.messageSquare,
            tooltip: 'Mensagens Diretas',
            badgeCount: 2,
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.border, height: 1),
          ),
          // Servers list
          Expanded(
            child: ListView.builder(
              itemCount: uxServers.length,
              itemBuilder: (context, index) {
                final server = uxServers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildServerRailButton(server),
                );
              },
            ),
          ),
          // Add Server button
          _buildRailIcon(
            icon: LucideIcons.plus,
            tooltip: 'Adicionar Servidor',
            accentColor: AppColors.green,
            onTap: () {},
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildRailIcon({
    required IconData icon,
    required String tooltip,
    bool isActive = false,
    Color? accentColor,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isActive ? 16 : 24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? (accentColor ?? AppColors.accent) : AppColors.panel,
            borderRadius: BorderRadius.circular(isActive ? 16 : 24),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : AppColors.dim,
                  size: 22,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerRailButton(ServerData server) {
    final initials = server.name.length >= 2
        ? server.name.substring(0, 2).toUpperCase()
        : server.name.toUpperCase();

    return Tooltip(
      message: server.name,
      child: InkWell(
        onTap: () => widget.onEnterServer(server.id),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: server.accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: server.accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: server.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (server.voiceCount > 0)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.volume2, size: 8, color: Colors.black),
                        const SizedBox(width: 2),
                        Text(
                          '${server.voiceCount}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.compass, color: AppColors.accent, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Hub Comunitário',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              const Spacer(),
              // Search bar
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.deep,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.search, size: 16, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: AppColors.text, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Live WebRTC Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.radio, size: 13, color: AppColors.green),
                    SizedBox(width: 6),
                    Text(
                      'LiveKit SFU Online',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: uxCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.deep,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.dim,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryGrid(List<ServerData> servers) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Row(
          children: [
            Icon(LucideIcons.trendingUp, size: 18, color: AppColors.yellow),
            SizedBox(width: 8),
            Text(
              'Servidores em Destaque',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 260,
          ),
          itemCount: servers.length,
          itemBuilder: (context, index) {
            final server = servers[index];
            return _buildServerCard(server);
          },
        ),
      ],
    );
  }

  Widget _buildServerCard(ServerData server) {
    final activeUsers = uxServerPresences[server.id] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with badges
          Stack(
            children: [
              Image.network(
                server.banner,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 110,
                  color: server.accentColor.withValues(alpha: 0.3),
                  child: Center(
                    child: Icon(LucideIcons.gamepad2, color: server.accentColor, size: 36),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    server.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.users, size: 12, color: AppColors.dim),
                      const SizedBox(width: 4),
                      Text(
                        '${server.memberCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              if (server.activeChannel.isNotEmpty)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.volume2, size: 12, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          server.activeChannel,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Server Information
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          server.name,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeUsers.isNotEmpty)
                        Text(
                          '${activeUsers.length} em chamada',
                          style: const TextStyle(color: AppColors.green, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      server.description,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => widget.onEnterServer(server.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Entrar no Servidor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(LucideIcons.chevronRight, size: 14),
                          ],
                        ),
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

  Widget _buildRightActivityPanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Icon(LucideIcons.activity, size: 16, color: AppColors.accent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Amigos & Atividades',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...uxActivities.map((act) => _buildActivityItem(act)),
        const Divider(color: AppColors.border, height: 28),
        const Row(
          children: [
            Icon(LucideIcons.atSign, size: 16, color: AppColors.yellow),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Menções Recentes',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...uxMentions.map((men) => _buildMentionItem(men)),
      ],
    );
  }

  Widget _buildActivityItem(ActivityData act) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: act.color.withValues(alpha: 0.2),
            child: Text(
              act.initials,
              style: TextStyle(color: act.color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.text, fontSize: 12),
                    children: [
                      TextSpan(text: act.user, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' ${act.action}', style: const TextStyle(color: AppColors.dim)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${act.server} • ${act.time}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionItem(MentionData men) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${men.server} ${men.channel}',
                  style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(men.time, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            men.preview,
            style: const TextStyle(color: AppColors.dim, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallBar() {
    final serverName = widget.activeCall?['serverName'] ?? 'ProjectNBX';
    final channelName = widget.activeCall?['channelName'] ?? 'Voz Geral';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voz Conectada: $channelName',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$serverName • Opus 48kHz (DTX) • 11ms',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          // Mute Button
          IconButton(
            onPressed: widget.onToggleMute,
            icon: Icon(
              widget.isMuted ? LucideIcons.micOff : LucideIcons.mic,
              size: 18,
              color: widget.isMuted ? AppColors.red : AppColors.text,
            ),
          ),
          // Deafen Button
          IconButton(
            onPressed: widget.onToggleDeafen,
            icon: Icon(
              widget.isDeafened ? LucideIcons.volumeX : LucideIcons.headphones,
              size: 18,
              color: widget.isDeafened ? AppColors.red : AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          // Disconnect
          ElevatedButton.icon(
            onPressed: widget.onDisconnectCall,
            icon: const Icon(LucideIcons.phoneOff, size: 14, color: Colors.white),
            label: const Text('Desconectar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
