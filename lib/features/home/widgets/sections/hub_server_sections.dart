import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/home/widgets/create_server_card.dart';
import 'package:projectnbx/features/home/widgets/hub_server_card.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';

class HubServerSections extends StatelessWidget {
  final List<ServerModel> servers;
  final ValueChanged<String> onSelectServer;

  const HubServerSections({
    super.key,
    required this.servers,
    required this.onSelectServer,
  });

  Widget _buildSectionTitle(bool isDark, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<ServerModel> list) {
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1050) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1440) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 4;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 226,
          ),
          itemBuilder: (context, index) {
            final server = list[index];
            return HubServerCard(
              server: server,
              onTap: () => onSelectServer(server.id),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (servers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(isDark, 'MEUS SERVIDORES', 0),
          const SizedBox(height: 12),
          const CreateServerCard(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(isDark, 'MEUS SERVIDORES', servers.length),
        const SizedBox(height: 12),
        _buildGrid(context, servers),
      ],
    );
  }
}
