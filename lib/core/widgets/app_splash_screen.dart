import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/updater/update_controller.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/servers/controllers/servers_controller.dart';

class AppSplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const AppSplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends ConsumerState<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  String _statusText = 'Iniciando o Just Talking...';
  double _progress = 0.15;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _animController.repeat(reverse: true);
    _runBootSequence();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animController.dispose();
    super.dispose();
  }

  Future<void> _runBootSequence() async {
    // 1. Passo 1: Início
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_isDisposed) return;
    setState(() {
      _statusText = 'Verificando atualizações...';
      _progress = 0.40;
    });

    // 2. Passo 2: Verificação silenciosa de updates
    try {
      await ref
          .read(updateControllerProvider.notifier)
          .checkForUpdates(silent: true)
          .timeout(const Duration(milliseconds: 1500));
    } catch (_) {}

    if (_isDisposed) return;
    setState(() {
      _statusText = 'Carregando servidores e canais em cache...';
      _progress = 0.75;
    });

    // 3. Passo 3: Restauração de sessão e aquecimento de cache
    try {
      await ref
          .read(authControllerProvider.notifier)
          .restoreSession()
          .timeout(const Duration(milliseconds: 1000));

      final authState = ref.read(authControllerProvider);
      if (authState.isAuthenticated) {
        // Carrega servidores em background (já lê o cache local instantaneamente)
        ref.read(serversControllerProvider.notifier).loadServers();
      }
    } catch (_) {}

    if (_isDisposed) return;
    setState(() {
      _statusText = 'Tudo pronto!';
      _progress = 1.0;
    });

    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!_isDisposed) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCanvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo com animação suave de respiração (Discord-like)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.darkBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkPrimary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SvgPicture.asset(
                      'assets/brand/nbx-projects-symbol-dark.svg',
                      semanticsLabel: 'Just Talking Logo',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Nome do App
            Text(
              'Just Talking',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.darkTextPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),

            // Subtítulo
            Text(
              'NBX Projects • Voz e colaboração em tempo real',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.darkTextMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Barra de progresso fina e minimalista
            SizedBox(
              width: 180,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.darkBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.darkPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Texto dinâmico de status com transição suave
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _statusText,
                key: ValueKey<String>(_statusText),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
