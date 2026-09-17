import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/network/api_status_controller.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:window_manager/window_manager.dart';

class ApiOfflineScreen extends ConsumerStatefulWidget {
  const ApiOfflineScreen({super.key});

  @override
  ConsumerState<ApiOfflineScreen> createState() => _ApiOfflineScreenState();
}

class _ApiOfflineScreenState extends ConsumerState<ApiOfflineScreen> {
  Timer? _autoRetryTimer;
  String? _statusFeedback;

  @override
  void initState() {
    super.initState();
    // Agenda verificação periódica a cada 20 segundos em segundo plano
    _autoRetryTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        _handleRetry(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRetry({bool silent = false}) async {
    if (!silent) {
      setState(() => _statusFeedback = null);
    }

    final isOnline = await ref.read(apiStatusProvider.notifier).checkStatus();
    if (!mounted) return;

    if (isOnline) {
      ref.read(serversControllerProvider.notifier).loadServers();
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated) {
        ref.read(websocketClientProvider).connect();
      }
    } else if (!silent) {
      setState(() {
        _statusFeedback =
            'O servidor continua indisponível. Tentaremos novamente automaticamente.';
      });
    }
  }

  Widget _buildStatusTag({
    required IconData icon,
    required String label,
    required String status,
    required bool isDown,
    required bool isDark,
  }) {
    final statusColor =
        isDown ? const Color(0xFFEF4444) : const Color(0xFF4ADE80);
    final bg = isDown
        ? const Color(0xFFEF4444).withValues(alpha: 0.10)
        : const Color(0xFF4ADE80).withValues(alpha: 0.10);
    final border = isDown
        ? const Color(0xFFEF4444).withValues(alpha: 0.30)
        : const Color(0xFF4ADE80).withValues(alpha: 0.30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: statusColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final apiStatus = ref.watch(apiStatusProvider);
    final authState = ref.watch(authControllerProvider);

    final canvasBg = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimaryColor =
        isDark ? const Color(0xFF181926) : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor =
        isDark ? const Color(0xFF2B2D3F) : const Color(0xFFE2E8F0);
    final toggleBg =
        isDark ? const Color(0xFF1B1C2A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: canvasBg,
      body: Stack(
        children: [
          // Top Window Bar with Theme Toggle (Left), Drag Window Area (Center), and Window Controls (Right)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Theme Mode Switcher
                  Tooltip(
                    message: isDark
                        ? 'Alternar para Tema Claro'
                        : 'Alternar para Tema Escuro',
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .toggleTheme();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: toggleBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isDark ? LucideIcons.sun : LucideIcons.moon,
                            size: 15,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Drag Window Area
                  const Expanded(
                    child: DragToMoveArea(child: SizedBox.expand()),
                  ),
                  // Desktop Window Controls
                  const WindowControls(height: 38, buttonWidth: 42),
                ],
              ),
            ),
          ),

          // Centered Seamless Area (mesmo princípio da tela de oauth/login)
          Positioned.fill(
            top: 52,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ícone de Status do Servidor
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.cloudOff,
                              size: 28,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Brand Title
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.spaceGrotesk().copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Project',
                              style: TextStyle(color: textPrimary),
                            ),
                            TextSpan(
                              text: 'NBX',
                              style: TextStyle(color: primaryColor),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Título da Tela
                      Text(
                        'Serviços Temporariamente Indisponíveis',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Descrição
                      Text(
                        'O servidor backend está desligado ou em manutenção no momento.\nAcompanhe o status dos serviços abaixo:',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // As 3 Tags de Serviços Solicitadas: API, WebSocket, LiveKit
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildStatusTag(
                            icon: LucideIcons.server,
                            label: 'API',
                            status: apiStatus.apiStatusText,
                            isDown: apiStatus.isOffline,
                            isDark: isDark,
                          ),
                          _buildStatusTag(
                            icon: LucideIcons.radio,
                            label: 'WebSocket',
                            status: apiStatus.wsStatusText,
                            isDown: apiStatus.isOffline,
                            isDark: isDark,
                          ),
                          _buildStatusTag(
                            icon: LucideIcons.volume2,
                            label: 'LiveKit',
                            status: apiStatus.liveKitStatusText,
                            isDown: apiStatus.isOffline,
                            isDark: isDark,
                          ),
                        ],
                      ),

                      if (_statusFeedback != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          _statusFeedback!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),

                      // Botão Principal: Tentar Novamente
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: apiStatus.isChecking
                              ? null
                              : () => _handleRetry(silent: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: onPrimaryColor,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.borderPill,
                            ),
                          ),
                          child: apiStatus.isChecking
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          onPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Verificando conexão...',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      LucideIcons.refreshCw,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tentar Novamente',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Opção de Logout se houver sessão ativa
                      if (authState.isAuthenticated) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                            },
                            icon: const Icon(LucideIcons.logOut, size: 14),
                            label: Text(
                              'Desconectar da Conta',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
