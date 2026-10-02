import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/settings/widgets/section_header.dart';
import 'package:justtalking/features/voice/controllers/audio_devices_controller.dart';
import 'package:justtalking/features/voice/controllers/audio_settings_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VoiceSection extends ConsumerStatefulWidget {
  final bool isDark;
  final AppStrings strings;
  final bool isMobile;

  const VoiceSection({
    super.key,
    required this.isDark,
    required this.strings,
    this.isMobile = false,
  });

  @override
  ConsumerState<VoiceSection> createState() => _VoiceSectionState();
}

class _VoiceSectionState extends ConsumerState<VoiceSection> {
  double _inputVolume = 1.0;
  double _outputVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final strings = widget.strings;
    final audioState = ref.watch(audioDevicesProvider);
    final audioNotifier = ref.read(audioDevicesProvider.notifier);
    final audioSettings = ref.watch(audioSettingsProvider);
    final audioSettingsNotifier = ref.read(audioSettingsProvider.notifier);

    final inputItems = audioState.inputDevices.isNotEmpty
        ? audioState.inputDevices.map((d) {
            final label = d.label.isNotEmpty
                ? d.label
                : 'Microfone (${d.deviceId.substring(0, d.deviceId.length.clamp(0, 8))})';
            return DropdownMenuItem(
              value: d.deviceId,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList()
        : [
            const DropdownMenuItem(
              value: 'default',
              child: Text('Microfone Padrão do Sistema'),
            ),
          ];

    final outputItems = audioState.outputDevices.isNotEmpty
        ? audioState.outputDevices.map((d) {
            final label = d.label.isNotEmpty
                ? d.label
                : 'Alto-falantes (${d.deviceId.substring(0, d.deviceId.length.clamp(0, 8))})';
            return DropdownMenuItem(
              value: d.deviceId,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList()
        : [
            const DropdownMenuItem(
              value: 'default',
              child: Text('Alto-falantes Padrão do Sistema'),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SectionHeader(
                isDark: isDark,
                title: strings.voiceAndVideo,
                description: strings.voiceDescription,
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Detectar novos microfones e fones conectados',
              child: InkWell(
                onTap: audioState.isLoading
                    ? null
                    : () => audioNotifier.loadDevices(),
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (audioState.isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          LucideIcons.refreshCw,
                          size: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        'Reescanear',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Device Selectors
        _buildDeviceDropdown(
          isDark,
          strings.inputDevice,
          audioState.selectedInputDeviceId,
          inputItems,
          (val) {
            if (val != null) audioNotifier.selectInputDevice(val);
          },
        ),

        const SizedBox(height: 14),

        // Input Volume Slider
        _buildSliderRow(
          isDark,
          strings.inputVolume,
          _inputVolume,
          (val) => setState(() => _inputVolume = val),
        ),

        const SizedBox(height: 20),

        _buildDeviceDropdown(
          isDark,
          strings.outputDevice,
          audioState.selectedOutputDeviceId,
          outputItems,
          (val) {
            if (val != null) audioNotifier.selectOutputDevice(val);
          },
        ),

        const SizedBox(height: 14),

        // Output Volume Slider
        _buildSliderRow(
          isDark,
          strings.outputVolume,
          _outputVolume,
          (val) => setState(() => _outputVolume = val),
        ),

        const SizedBox(height: 24),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        const SizedBox(height: 20),

        // Input Sensitivity & Noise Gate
        Text(
          strings.inputSensitivity,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        _buildNoiseGateCard(
          isDark,
          strings,
          audioSettings,
          audioSettingsNotifier,
        ),

        const SizedBox(height: 16),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        const SizedBox(height: 20),

        // Voice Processing Toggles
        Text(
          strings.audioProcessing,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        _buildSwitchTile(
          isDark,
          strings.noiseSuppression,
          strings.noiseSuppressionDesc,
          audioSettings.noiseSuppression,
          (val) => audioSettingsNotifier.setNoiseSuppression(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.typingNoiseSuppression,
          strings.typingNoiseSuppressionDesc,
          audioSettings.typingNoiseDetection,
          (val) => audioSettingsNotifier.setTypingNoiseDetection(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.echoCancellation,
          strings.echoCancellationDesc,
          audioSettings.echoCancellation,
          (val) => audioSettingsNotifier.setEchoCancellation(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.compressor,
          strings.compressorDesc,
          audioSettings.compressorEnabled,
          (val) => audioSettingsNotifier.setCompressorEnabled(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.highPassFilter,
          strings.highPassFilterDesc,
          audioSettings.highPassFilter,
          (val) => audioSettingsNotifier.setHighPassFilter(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.vadOptimization,
          strings.vadOptimizationDesc,
          audioSettings.vadOptimization,
          (val) => audioSettingsNotifier.setVadOptimization(val),
        ),
        _buildSwitchTile(
          isDark,
          'Evitar Atenuação de Áudio no Windows',
          'Impede que o Windows reduza o volume de jogos e outros aplicativos durante chamadas de voz',
          audioSettings.disableWindowsDucking,
          (val) => audioSettingsNotifier.setDisableWindowsDucking(val),
        ),
      ],
    );
  }

  Widget _buildNoiseGateCard(
    bool isDark,
    AppStrings strings,
    AudioSettings audioSettings,
    AudioSettingsNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.autoSensitivity,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      strings.autoSensitivityDesc,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: audioSettings.autoNoiseGate,
                activeThumbColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                activeTrackColor:
                    (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        .withValues(alpha: 0.38),
                onChanged: (val) => notifier.setAutoNoiseGate(val),
              ),
            ],
          ),
          if (!audioSettings.autoNoiseGate) ...[
            const SizedBox(height: 16),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.noiseGateThreshold,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        strings.noiseGateThresholdDesc,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorderFocus
                          : AppColors.lightBorderFocus,
                    ),
                  ),
                  child: Text(
                    '${(-60 + audioSettings.noiseGateThreshold * 50).toInt()} dB (${(audioSettings.noiseGateThreshold * 100).toInt()}%)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: audioSettings.noiseGateThreshold,
                    child: Container(
                      height: 10,
                      color: Colors.redAccent.withValues(alpha: 0.65),
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: (1.0 - audioSettings.noiseGateThreshold).clamp(
                      0.0,
                      1.0,
                    ),
                    child: Container(
                      height: 10,
                      color: isDark
                          ? AppColors.darkSage.withValues(alpha: 0.75)
                          : AppColors.lightSage.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Silêncio (Corta Teclado / Cliques)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: Colors.redAccent,
                  ),
                ),
                Text(
                  'Transmissão Ativa (Voz)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: isDark ? AppColors.darkSage : AppColors.lightSage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                inactiveTrackColor: isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                thumbColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                overlayColor:
                    (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        .withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: audioSettings.noiseGateThreshold,
                min: 0.0,
                max: 1.0,
                onChanged: (val) => notifier.setNoiseGateThreshold(val),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.noiseGateRelease,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        strings.noiseGateReleaseDesc,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      inactiveTrackColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      thumbColor: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      overlayColor:
                          (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: 0.2),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: audioSettings.noiseGateReleaseMs.toDouble(),
                      min: 100,
                      max: 600,
                      divisions: 10,
                      label: '${audioSettings.noiseGateReleaseMs}ms',
                      onChanged: (val) =>
                          notifier.setNoiseGateReleaseMs(val.toInt()),
                    ),
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    '${audioSettings.noiseGateReleaseMs}ms',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceDropdown(
    bool isDark,
    String label,
    String? currentValue,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) {
    final safeValue =
        (currentValue != null && items.any((it) => it.value == currentValue))
            ? currentValue
            : (items.isNotEmpty ? items.first.value : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: DropdownButton<String>(
            value: safeValue,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow(
    bool isDark,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              inactiveTrackColor:
                  isDark ? AppColors.darkBorder : AppColors.lightBorder,
              thumbColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              overlayColor:
                  (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                      .withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 45,
          child: Text(
            '${(value * 100).toInt()}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    bool isDark,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor:
                isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            activeTrackColor:
                (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    .withValues(alpha: 0.38),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
