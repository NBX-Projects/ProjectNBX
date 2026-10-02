import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/updater/update_controller.dart';
import 'package:justtalking/core/updater/update_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TopBarUpdateButton extends ConsumerStatefulWidget {
  final bool isDark;
  final Color? accentColor;

  const TopBarUpdateButton({
    super.key,
    required this.isDark,
    this.accentColor,
  });

  @override
  ConsumerState<TopBarUpdateButton> createState() => _TopBarUpdateButtonState();
}

class _TopBarUpdateButtonState extends ConsumerState<TopBarUpdateButton> {
  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateControllerProvider);
    final updateNotifier = ref.read(updateControllerProvider.notifier);

    // Se não há atualização e o status não é ativo/relevante, não ocupa espaço
    if (!updateState.isUpdateAvailable &&
        updateState.status != UpdateStatus.error) {
      return const SizedBox.shrink();
    }

    final isDark = widget.isDark;
    final primaryColor = widget.accentColor ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final sageColor = isDark ? AppColors.darkSage : AppColors.lightSage;

    final version = updateState.latestRelease?.version ?? '';
    final progress = updateState.downloadProgress.clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    String tooltip;
    VoidCallback? onTap;
    Widget content;

    switch (updateState.status) {
      case UpdateStatus.available:
        tooltip = 'Nova versão v$version disponível • Clique para baixar';
        onTap = () => updateNotifier.startDownload();
        // Apenas a seta para baixo colorida, sem bolinha
        content = Icon(
          LucideIcons.arrowDownToLine,
          size: 18,
          color: primaryColor,
        );
        break;

      case UpdateStatus.downloading:
        tooltip = 'Baixando atualização: $percent%';
        onTap = null;
        // Apenas o círculo de progresso limpo sem bordas ao redor
        content = SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                strokeWidth: 2.4,
                backgroundColor: isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              if (percent > 0)
                Text(
                  '$percent',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                )
              else
                Icon(
                  LucideIcons.arrowDown,
                  size: 11,
                  color: primaryColor,
                ),
            ],
          ),
        );
        break;

      case UpdateStatus.readyToInstall:
        tooltip =
            'Atualização v$version pronta! Clique para reiniciar e atualizar';
        onTap = () => updateNotifier.applyUpdate(silent: true);
        content = Icon(
          LucideIcons.refreshCw,
          size: 17,
          color: sageColor,
        );
        break;

      case UpdateStatus.error:
        tooltip = updateState.errorMessage ??
            'Erro ao baixar. Clique para tentar novamente';
        onTap = () => updateNotifier.startDownload();
        content = Icon(
          LucideIcons.alertCircle,
          size: 17,
          color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
        );
        break;

      default:
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          mouseCursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(updateState.status),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
