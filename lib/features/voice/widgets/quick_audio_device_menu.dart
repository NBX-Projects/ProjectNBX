import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/settings/screens/settings_screen.dart';
import 'package:projectnbx/features/voice/controllers/audio_devices_controller.dart';
import 'package:projectnbx/features/voice/controllers/audio_settings_controller.dart';

import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';

class QuickAudioDeviceMenu extends ConsumerStatefulWidget {
  final bool initialShowInput;

  const QuickAudioDeviceMenu({
    super.key,
    this.initialShowInput = true,
  });

  static Future<void> show(
    BuildContext context, {
    required GlobalKey anchorKey,
    bool isInput = true,
  }) async {
    final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    const menuWidth = 310.0;
    const menuHeight = 440.0;

    // Garante que o menu não transborde lateralmente
    double left = offset.dx;
    if (left + menuWidth > screenWidth - 12) {
      left = screenWidth - menuWidth - 12;
    }
    if (left < 12) left = 12;

    // Detecta se o elemento âncora está no topo ou na base da tela
    final openUpward = offset.dy > screenHeight / 2;
    double? top;
    double? bottom;

    if (openUpward) {
      bottom = screenHeight - offset.dy + 8;
      if (bottom + menuHeight > screenHeight - 20) {
        bottom = 20;
      }
    } else {
      top = offset.dy + size.height + 8;
      if (top + menuHeight > screenHeight - 20) {
        top = screenHeight - menuHeight - 20;
      }
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'QuickAudioMenu',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              bottom: bottom,
              child: Material(
                color: Colors.transparent,
                child: QuickAudioDeviceMenu(initialShowInput: isInput),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            alignment: openUpward ? Alignment.bottomLeft : Alignment.topLeft,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<QuickAudioDeviceMenu> createState() => _QuickAudioDeviceMenuState();
}

class _QuickAudioDeviceMenuState extends ConsumerState<QuickAudioDeviceMenu>
    with SingleTickerProviderStateMixin {
  bool _expandedInput = false;
  bool _expandedOutput = false;
  bool _expandedProfile = false;

  late AnimationController _vuController;

  @override
  void initState() {
    super.initState();
    _expandedInput = widget.initialShowInput;
    _expandedOutput = !widget.initialShowInput;

    _vuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _vuController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _vuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audioDevicesState = ref.watch(audioDevicesProvider);
    final audioDevicesNotifier = ref.read(audioDevicesProvider.notifier);
    final audioSettings = ref.watch(audioSettingsProvider);
    final audioSettingsNotifier = ref.read(audioSettingsProvider.notifier);

    final bgCard = isDark ? const Color(0xFF181926) : Colors.white;
    final borderColor = isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFCAD3F5) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFFA5ADCB) : const Color(0xFF64748B);
    final primaryAccent = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      width: 310,
      constraints: const BoxConstraints(maxHeight: 520),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DISPOSITIVO DE ENTRADA
            _buildDeviceSection(
              title: 'Dispositivo de entrada',
              currentLabel: audioDevicesState.selectedInputLabel,
              isExpanded: _expandedInput,
              isDark: isDark,
              onToggle: () {
                setState(() {
                  _expandedInput = !_expandedInput;
                  if (_expandedInput) {
                    _expandedOutput = false;
                    _expandedProfile = false;
                  }
                });
              },
              items: audioDevicesState.inputDevices.map((d) {
                final isSelected = d.deviceId == audioDevicesState.selectedInputDeviceId ||
                    (audioDevicesState.selectedInputDeviceId == null && d.deviceId == 'default');
                return _buildDeviceItem(
                  label: d.label,
                  isSelected: isSelected,
                  isDark: isDark,
                  primaryAccent: primaryAccent,
                  onTap: () {
                    audioDevicesNotifier.selectInputDevice(d.deviceId);
                    setState(() => _expandedInput = false);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 6),

            // 2. DISPOSITIVO DE SAÍDA
            _buildDeviceSection(
              title: 'Dispositivo de saída',
              currentLabel: audioDevicesState.selectedOutputLabel,
              isExpanded: _expandedOutput,
              isDark: isDark,
              onToggle: () {
                setState(() {
                  _expandedOutput = !_expandedOutput;
                  if (_expandedOutput) {
                    _expandedInput = false;
                    _expandedProfile = false;
                  }
                });
              },
              items: audioDevicesState.outputDevices.map((d) {
                final isSelected = d.deviceId == audioDevicesState.selectedOutputDeviceId ||
                    (audioDevicesState.selectedOutputDeviceId == null && d.deviceId == 'default');
                return _buildDeviceItem(
                  label: d.label,
                  isSelected: isSelected,
                  isDark: isDark,
                  primaryAccent: primaryAccent,
                  onTap: () {
                    audioDevicesNotifier.selectOutputDevice(d.deviceId);
                    setState(() => _expandedOutput = false);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 6),

            // 3. PERFIL DE ENTRADA (PRESETS DE ÁUDIO)
            _buildDeviceSection(
              title: 'Perfil de entrada',
              currentLabel: _getProfileLabel(audioSettings.inputProfile),
              isExpanded: _expandedProfile,
              isDark: isDark,
              onToggle: () {
                setState(() {
                  _expandedProfile = !_expandedProfile;
                  if (_expandedProfile) {
                    _expandedInput = false;
                    _expandedOutput = false;
                  }
                });
              },
              items: [
                _buildDeviceItem(
                  label: 'Padrão (Cancelamento + Supressão)',
                  isSelected: audioSettings.inputProfile == 'padrao',
                  isDark: isDark,
                  primaryAccent: primaryAccent,
                  onTap: () {
                    audioSettingsNotifier.applyProfile('padrao');
                    setState(() => _expandedProfile = false);
                  },
                ),
                _buildDeviceItem(
                  label: 'Estúdio / Puro (Sem filtros / Anti-chiado)',
                  isSelected: audioSettings.inputProfile == 'estudio',
                  isDark: isDark,
                  primaryAccent: primaryAccent,
                  onTap: () {
                    audioSettingsNotifier.applyProfile('estudio');
                    setState(() => _expandedProfile = false);
                  },
                ),
                _buildDeviceItem(
                  label: 'Isolamento Máximo (Gate + Supressão Alta)',
                  isSelected: audioSettings.inputProfile == 'isolamento',
                  isDark: isDark,
                  primaryAccent: primaryAccent,
                  onTap: () {
                    audioSettingsNotifier.applyProfile('isolamento');
                    setState(() => _expandedProfile = false);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 4. VOLUME DE ENTRADA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Volume de entrada',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${(audioSettings.inputVolume * 100).toInt()}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                inactiveTrackColor: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: audioSettings.inputVolume,
                onChanged: (val) {
                  audioSettingsNotifier.setInputVolume(val);
                },
              ),
            ),

            const SizedBox(height: 6),

            // 5. NÍVEL DE ENTRADA (VU METER INDICATOR)
            Text(
              'Nível de entrada',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            _buildVuMeter(isDark),

            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 8),

            // 6. LINK PARA CONFIGURAÇÕES DE VOZ
            InkWell(
              onTap: () {
                Navigator.pop(context);
                SettingsScreen.show(context, initialSection: 'voice');
              },
              borderRadius: AppRadius.borderSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.settings,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Configurações de voz',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProfileLabel(String key) {
    switch (key) {
      case 'estudio':
        return 'Estúdio (Som Puro)';
      case 'isolamento':
        return 'Isolamento Máximo';
      case 'padrao':
      default:
        return 'Padrão do Sistema';
    }
  }

  Widget _buildDeviceSection({
    required String title,
    required String currentLabel,
    required bool isExpanded,
    required bool isDark,
    required VoidCallback onToggle,
    required List<Widget> items,
  }) {
    final textPrimary = isDark ? const Color(0xFFCAD3F5) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFFA5ADCB) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: AppRadius.borderSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 16,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141520) : const Color(0xFFF8FAFC),
              borderRadius: AppRadius.borderSm,
              border: Border.all(
                color: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceItem({
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color primaryAccent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderXs,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? const Color(0xFFF5CBA7) : const Color(0xFF2D6A4F))
                      : (isDark ? const Color(0xFFCAD3F5) : const Color(0xFF334155)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 14,
                color: isDark ? const Color(0xFFF5CBA7) : const Color(0xFF2D6A4F),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVuMeter(bool isDark) {
    const totalBars = 24;
    final voiceState = ref.watch(voiceStateProvider);
    final isMuted = voiceState.isMicMuted || voiceState.isDeafened;

    return AnimatedBuilder(
      animation: _vuController,
      builder: (context, _) {
        final activeBars = isMuted
            ? 0
            : ((_vuController.value * 14) + 4).clamp(0, totalBars).toInt();
        return Row(
          children: List.generate(totalBars, (index) {
            final isActive = index <= activeBars;
            Color barColor;
            if (index < 16) {
              barColor = isDark ? const Color(0xFFA8C5B5) : const Color(0xFF2D6A4F);
            } else if (index < 20) {
              barColor = const Color(0xFFFBBF24);
            } else {
              barColor = const Color(0xFFEF4444);
            }

            return Expanded(
              child: Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? barColor
                      : (isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
