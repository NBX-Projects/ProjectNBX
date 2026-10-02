import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/servers/models/server_join_request_model.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:justtalking/features/servers/widgets/server_join_requests_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ServerPendingRequestsCard extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  final ServerModel server;
  final List<ServerJoinRequestModel> pendingRequests;
  final VoidCallback onRequestsChanged;
  final Future<void> Function(ServerJoinRequestModel req) onAcceptRequest;
  final Future<void> Function(ServerJoinRequestModel req) onRejectRequest;

  const ServerPendingRequestsCard({
    super.key,
    this.isMobile = false,
    required this.isDark,
    required this.server,
    required this.pendingRequests,
    required this.onRequestsChanged,
    required this.onAcceptRequest,
    required this.onRejectRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingRequests.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B231F) : const Color(0xFFF0FDF4),
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.userCheck,
                    size: 16,
                    color: Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PEDIDOS DE ENTRADA PENDENTES (${pendingRequests.length})',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => ServerJoinRequestsDialog.show(
                  context,
                  server,
                  onRequestsChanged: onRequestsChanged,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF22C55E),
                ),
                child: Text(
                  'Ver Todos',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingRequests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final req = pendingRequests[index];
              final displayName = req.userName ?? 'Usuário';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141520) : Colors.white,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor:
                          const Color(0xFF22C55E).withValues(alpha: 0.2),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (req.message.isNotEmpty)
                            Text(
                              req.message,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Recusar pedido',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => onRejectRequest(req),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => onAcceptRequest(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.check,
                            size: 12,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Aceitar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
