import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/shortcuts/controllers/shortcuts_controller.dart';
import 'package:justtalking/core/shortcuts/models/app_shortcut_action.dart';
import 'package:justtalking/core/shortcuts/widgets/shortcut_record_dialog.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/settings/widgets/dialogs/ptt_key_record_dialog.dart';
import 'package:justtalking/features/settings/widgets/section_header.dart';
import 'package:justtalking/features/voice/controllers/audio_settings_controller.dart';
import 'package:justtalking/features/voice/controllers/voice_state_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HotkeysSection extends ConsumerWidget {
  final bool isDark;
  final AppStrings strings;
  final bool isMobile;

  const HotkeysSection({
    super.key,
    required this.isDark,
    required this.strings,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcutsState = ref.watch(shortcutsProvider);
    final shortcutsNotifier = ref.read(shortcutsProvider.notifier);
    final audioSettings = ref.watch(audioSettingsProvider);
    final audioSettingsNotifier = ref.read(audioSettingsProvider.notifier);
    final voiceNotifier = ref.read(voiceStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                isDark: isDark,
                title: strings.hotkeysAndPTT,
                description: strings.hotkeysDescription,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkDanger
                        : AppColors.lightDanger,
                    side: BorderSide(
                      color:
                          (isDark
                                  ? AppColors.darkDanger
                                  : AppColors.lightDanger)
                              .withValues(alpha: 0.4),
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderSm,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => _confirmResetAllShortcuts(context, ref, isDark),
                  icon: const Icon(LucideIcons.rotateCcw, size: 14),
                  label: Text(
                    'Restaurar Padrões',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SectionHeader(
                  isDark: isDark,
                  title: strings.hotkeysAndPTT,
                  description: strings.hotkeysDescription,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.darkDanger
                      : AppColors.lightDanger,
                  side: BorderSide(
                    color:
                        (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                            .withValues(alpha: 0.4),
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderSm,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () => _confirmResetAllShortcuts(context, ref, isDark),
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
                label: Text(
                  'Restaurar Padrões',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),

        // Input Mode Selection
        Text(
          strings.inputMode,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),

        if (isMobile)
          Column(
            children: [
              _buildInputModeCard(
                title: strings.voiceActivity,
                description: strings.voiceActivityDesc,
                isSelected: !audioSettings.isPushToTalk,
                icon: LucideIcons.mic,
                isDark: isDark,
                onTap: () {
                  audioSettingsNotifier.setIsPushToTalk(false);
                  voiceNotifier.setMicMuted(false);
                },
              ),
              const SizedBox(height: 10),
              _buildInputModeCard(
                title: strings.pushToTalk,
                description: strings.pushToTalkDesc,
                isSelected: audioSettings.isPushToTalk,
                icon: LucideIcons.radio,
                isDark: isDark,
                onTap: () {
                  audioSettingsNotifier.setIsPushToTalk(true);
                  voiceNotifier.setMicMuted(true);
                },
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildInputModeCard(
                  title: strings.voiceActivity,
                  description: strings.voiceActivityDesc,
                  isSelected: !audioSettings.isPushToTalk,
                  icon: LucideIcons.mic,
                  isDark: isDark,
                  onTap: () {
                    audioSettingsNotifier.setIsPushToTalk(false);
                    voiceNotifier.setMicMuted(false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputModeCard(
                  title: strings.pushToTalk,
                  description: strings.pushToTalkDesc,
                  isSelected: audioSettings.isPushToTalk,
                  icon: LucideIcons.radio,
                  isDark: isDark,
                  onTap: () {
                    audioSettingsNotifier.setIsPushToTalk(true);
                    voiceNotifier.setMicMuted(true);
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        if (audioSettings.isPushToTalk) ...[
          Container(
            padding: const EdgeInsets.all(16),
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
                        strings.pttKeyLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        strings.pttKeyDesc,
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
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => PttKeyRecordDialog.show(
                    context,
                    isDark: isDark,
                    notifier: audioSettingsNotifier,
                    currentKeyLabel: audioSettings.pttKeyLabel,
                  ),
                  borderRadius: AppRadius.borderSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          audioSettings.pttKeyLabel,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.pencil,
                          size: 12,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Categorized Shortcuts
        ...ShortcutCategory.values.map((category) {
          final actions = AppShortcutAction.values
              .where((a) => a.category == category)
              .toList();
          if (actions.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      size: 14,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.label.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: List.generate(actions.length, (index) {
                    final action = actions[index];
                    final combo = shortcutsState.getCombination(action);
                    final isCustomized = shortcutsState.isCustomized(action);
                    final isLast = index == actions.length - 1;

                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.lightBorder.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.lightSurfaceElevated,
                                        borderRadius: AppRadius.borderSm,
                                      ),
                                      child: Icon(
                                        action.icon,
                                        size: 15,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        action.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isCustomized) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (isDark
                                                      ? AppColors.darkPrimary
                                                      : AppColors.lightPrimary)
                                                  .withValues(alpha: 0.15),
                                          borderRadius: AppRadius.borderXs,
                                        ),
                                        child: Text(
                                          'Editado',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.darkPrimary
                                                : AppColors.lightPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  action.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    // Badge de atalho clicável
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => ShortcutRecordDialog.show(
                                          context,
                                          action: action,
                                          currentCombination: combo,
                                        ),
                                        mouseCursor: SystemMouseCursors.click,
                                        borderRadius: AppRadius.borderSm,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: combo != null
                                                ? (isDark
                                                      ? AppColors
                                                            .darkSurfaceElevated
                                                      : AppColors
                                                            .lightSurfaceElevated)
                                                : Colors.transparent,
                                            borderRadius: AppRadius.borderSm,
                                            border: Border.all(
                                              color: combo != null
                                                  ? (isDark
                                                        ? AppColors
                                                              .darkBorderFocus
                                                        : AppColors
                                                              .lightBorderFocus)
                                                  : (isDark
                                                        ? AppColors.darkBorder
                                                        : AppColors
                                                              .lightBorder),
                                            ),
                                          ),
                                          child: Text(
                                            combo?.toReadableString() ??
                                                'Nenhum atalho',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 11,
                                              fontWeight: combo != null
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: combo != null
                                                  ? (isDark
                                                        ? AppColors
                                                              .darkTextPrimary
                                                        : AppColors
                                                              .lightTextPrimary)
                                                  : (isDark
                                                        ? AppColors
                                                              .darkTextMuted
                                                        : AppColors
                                                              .lightTextMuted),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.pencil,
                                        size: 15,
                                      ),
                                      tooltip: 'Editar atalho',
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      onPressed: () =>
                                          ShortcutRecordDialog.show(
                                            context,
                                            action: action,
                                            currentCombination: combo,
                                          ),
                                    ),
                                    if (isCustomized)
                                      IconButton(
                                        icon: const Icon(
                                          LucideIcons.rotateCcw,
                                          size: 15,
                                        ),
                                        tooltip:
                                            'Restaurar padrão (${action.defaultCombination?.toReadableString() ?? "Nenhum"})',
                                        color: isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.lightPrimary,
                                        onPressed: () => shortcutsNotifier
                                            .resetShortcut(action),
                                      ),
                                    if (combo != null)
                                      IconButton(
                                        icon: const Icon(
                                          LucideIcons.trash2,
                                          size: 15,
                                        ),
                                        tooltip: 'Remover atalho',
                                        color: isDark
                                            ? AppColors.darkDanger
                                            : AppColors.lightDanger,
                                        onPressed: () => shortcutsNotifier
                                            .setShortcut(action, null),
                                      ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceElevated
                                        : AppColors.lightSurfaceElevated,
                                    borderRadius: AppRadius.borderSm,
                                  ),
                                  child: Icon(
                                    action.icon,
                                    size: 15,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              action.title,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors
                                                          .lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                          if (isCustomized) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (isDark
                                                            ? AppColors
                                                                  .darkPrimary
                                                            : AppColors
                                                                  .lightPrimary)
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                borderRadius:
                                                    AppRadius.borderXs,
                                              ),
                                              child: Text(
                                                'Editado',
                                                style:
                                                    GoogleFonts.jetBrainsMono(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isDark
                                                          ? AppColors
                                                                .darkPrimary
                                                          : AppColors
                                                                .lightPrimary,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        action.description,
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
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () => ShortcutRecordDialog.show(
                                    context,
                                    action: action,
                                    currentCombination: combo,
                                  ),
                                  mouseCursor: SystemMouseCursors.click,
                                  borderRadius: AppRadius.borderSm,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: combo != null
                                          ? (isDark
                                                ? AppColors.darkSurfaceElevated
                                                : AppColors
                                                      .lightSurfaceElevated)
                                          : Colors.transparent,
                                      borderRadius: AppRadius.borderSm,
                                      border: Border.all(
                                        color: combo != null
                                            ? (isDark
                                                  ? AppColors.darkBorderFocus
                                                  : AppColors.lightBorderFocus)
                                            : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.lightBorder),
                                      ),
                                    ),
                                    child: Text(
                                      combo?.toReadableString() ??
                                          'Nenhum atalho',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: combo != null
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: combo != null
                                            ? (isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary)
                                            : (isDark
                                                  ? AppColors.darkTextMuted
                                                  : AppColors.lightTextMuted),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.pencil,
                                    size: 14,
                                  ),
                                  tooltip: 'Editar atalho',
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  onPressed: () => ShortcutRecordDialog.show(
                                    context,
                                    action: action,
                                    currentCombination: combo,
                                  ),
                                ),
                                if (isCustomized)
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.rotateCcw,
                                      size: 14,
                                    ),
                                    tooltip:
                                        'Restaurar padrão (${action.defaultCombination?.toReadableString() ?? "Nenhum"})',
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.lightPrimary,
                                    onPressed: () =>
                                        shortcutsNotifier.resetShortcut(action),
                                  ),
                                if (combo != null)
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      size: 14,
                                    ),
                                    tooltip: 'Remover atalho',
                                    color: isDark
                                        ? AppColors.darkDanger
                                        : AppColors.lightDanger,
                                    onPressed: () => shortcutsNotifier
                                        .setShortcut(action, null),
                                  ),
                              ],
                            ),
                    );
                  }),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _confirmResetAllShortcuts(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        title: Text(
          'Restaurar Todos os Atalhos?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Todas as suas combinações de teclas personalizadas serão restauradas para os padrões de fábrica.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar Tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(shortcutsProvider.notifier).resetAllToDefault();
    }
  }

  Widget _buildInputModeCard({
    required String title,
    required String description,
    required bool isSelected,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (isSelected
                            ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary))
                        .withValues(alpha: 0.12),
                borderRadius: AppRadius.borderSm,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
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
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 16,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
          ],
        ),
      ),
    );
  }
}
