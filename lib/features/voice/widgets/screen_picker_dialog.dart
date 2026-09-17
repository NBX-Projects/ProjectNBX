import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/features/voice/controllers/screen_share_controller.dart';
import 'package:projectnbx/features/voice/services/screen_capture_source.dart';

class ScreenPickerDialog extends ConsumerStatefulWidget {
  final String channelId;

  const ScreenPickerDialog({
    super.key,
    required this.channelId,
  });

  static Future<bool?> show(BuildContext context, String channelId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ScreenPickerDialog(channelId: channelId),
    );
  }

  @override
  ConsumerState<ScreenPickerDialog> createState() => _ScreenPickerDialogState();
}

class _ScreenPickerDialogState extends ConsumerState<ScreenPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenShareControllerProvider.notifier).loadSources();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final state = ref.watch(screenShareControllerProvider);
    final controller = ref.read(screenShareControllerProvider.notifier);

    final screens = state.availableSources.where((s) => !s.isWindow).toList();
    final windows = state.availableSources.where((s) => s.isWindow).toList();

    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 720,
        height: 580,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.screenShare,
                    color: primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Compartilhar Tela',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    color: textSecondary,
                    onPressed: () => Navigator.of(context).pop(false),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // Abas de Telas / Janelas
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInput : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: isDark ? const Color(0xFF181926) : Colors.white,
                unselectedLabelColor: textSecondary,
                labelStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.monitor, size: 16),
                        const SizedBox(width: 8),
                        Text('Telas (${screens.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.appWindow, size: 16),
                        const SizedBox(width: 8),
                        Text('Janelas (${windows.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo das Abas
            Expanded(
              child: state.isLoadingSources
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSourceGrid(
                          screens,
                          state.selectedSource,
                          controller.selectSource,
                          isDark,
                          borderColor,
                          primaryColor,
                          textPrimary,
                          textSecondary,
                        ),
                        _buildSourceGrid(
                          windows,
                          state.selectedSource,
                          controller.selectSource,
                          isDark,
                          borderColor,
                          primaryColor,
                          textPrimary,
                          textSecondary,
                        ),
                      ],
                    ),
            ),

            const Divider(height: 1),

            // Rodapé com Seletor de Perfil de Qualidade e Botões de Ação
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                children: [
                  // Seletor de Perfil de Qualidade
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Qualidade de Transmissão',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: ScreenQualityProfile.all.map((profile) {
                          final isSelected = state.selectedProfile == profile;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => controller.selectProfile(profile),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? primaryColor : borderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  profile.label,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected ? primaryColor : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Botão Cancelar
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Botão Iniciar Transmissão
                  ElevatedButton(
                    onPressed: _isStarting || state.selectedSource == null
                        ? null
                        : () async {
                            final nav = Navigator.of(context);
                            setState(() => _isStarting = true);
                            final success = await controller.startScreenShare(widget.channelId);
                            if (mounted) {
                              setState(() => _isStarting = false);
                              if (success) {
                                nav.pop(true);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark ? const Color(0xFF181926) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      elevation: 0,
                    ),
                    child: _isStarting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Iniciar Transmissão',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceGrid(
    List<ScreenSource> sources,
    ScreenSource? selectedSource,
    void Function(ScreenSource) onSelect,
    bool isDark,
    Color borderColor,
    Color primaryColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (sources.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma fonte encontrada nesta categoria',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.25,
      ),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final isSelected = selectedSource?.id == source.id;

        return InkWell(
          onTap: () => onSelect(source),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInput : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? primaryColor : borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Prévia/Thumbnail
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: source.thumbnail != null && source.thumbnail!.isNotEmpty
                        ? Image.memory(
                            source.thumbnail!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(source),
                          )
                        : _buildFallbackIcon(source),
                  ),
                ),
                // Nome da Fonte
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primaryColor : textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackIcon(ScreenSource source) {
    return Center(
      child: Icon(
        source.isWindow ? LucideIcons.appWindow : LucideIcons.monitor,
        size: 36,
        color: Colors.white38,
      ),
    );
  }
}
