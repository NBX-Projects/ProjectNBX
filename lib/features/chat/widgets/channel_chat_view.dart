import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/utils/image_compressor.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/utils/chat_helpers.dart';
import 'package:projectnbx/features/chat/widgets/components/chat_bubble_components.dart';
import 'package:projectnbx/features/chat/widgets/components/confirm_delete_dialog.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';
import 'package:projectnbx/features/voice/widgets/immersive_stream_player.dart';

class ChannelChatView extends StatefulWidget {
  final bool isDark;
  final String activeChannelName;
  final String channelKey;
  final String username;
  final List<ChatMessage> messages;
  final TextEditingController messageController;
  final TextEditingController editMessageController;
  final ScrollController scrollController;
  final FocusNode? messageFocusNode;
  final String? editingMessageId;
  final bool isTransmitting;
  final bool isInVoice;
  final bool isConnectingVoice;
  final bool isVoiceConnected;
  final bool isRightSidebarVisible;
  final Color accentColor;
  final VoiceParticipantInfo? activeBroadcaster;
  final VoidCallback? onToggleTransmission;
  final VoidCallback? onToggleVoiceChannel;
  final VoidCallback? onToggleRightSidebar;
  final VoidCallback? onWatchLive;
  final void Function(String channelKey, String author) onSendMessage;
  final void Function(
    String channelKey,
    String author, {
    String? mediaUrl,
    String? mediaType,
  })?
  onSendMessageWithMedia;
  final Future<String?> Function(List<int> bytes, String filename)?
  onUploadMedia;
  final void Function(String messageId) onStartEditing;
  final VoidCallback onCancelEditing;
  final void Function(String messageId) onSaveEditing;
  final void Function(String messageId) onDeleteMessage;
  final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants;
  final String? clientSessionId;
  final String? connectedVoiceChannelId;

  const ChannelChatView({
    super.key,
    required this.isDark,
    required this.activeChannelName,
    required this.channelKey,
    required this.username,
    required this.messages,
    required this.messageController,
    required this.editMessageController,
    required this.scrollController,
    this.messageFocusNode,
    this.editingMessageId,
    this.isTransmitting = false,
    this.isInVoice = false,
    this.isConnectingVoice = false,
    this.isVoiceConnected = false,
    this.isRightSidebarVisible = false,
    this.accentColor = const Color(0xFFF5CBA7),
    this.activeBroadcaster,
    this.onToggleTransmission,
    this.onToggleVoiceChannel,
    this.onToggleRightSidebar,
    this.onWatchLive,
    required this.onSendMessage,
    this.onSendMessageWithMedia,
    this.onUploadMedia,
    required this.onStartEditing,
    required this.onCancelEditing,
    required this.onSaveEditing,
    required this.onDeleteMessage,
    this.voiceParticipants = const {},
    this.clientSessionId,
    this.connectedVoiceChannelId,
  });

  @override
  State<ChannelChatView> createState() => _ChannelChatViewState();
}

class _ChannelChatViewState extends State<ChannelChatView> {
  PlatformFile? _attachedFile;
  bool _isUploading = false;
  bool _isDragging = false;
  bool _isCompressing = false;

  /// Processa e comprime uma imagem (via picker ou drag & drop)
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB máximo

  Future<void> _processAndAttachImage({
    required Uint8List bytes,
    required String filename,
    String? path,
  }) async {
    if (!ImageCompressor.isImageFile(filename)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formato de imagem não suportado. Utilize PNG, JPG, WEBP, GIF ou BMP.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    if (bytes.length > maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O arquivo selecionado excede o limite máximo permitido de 5 MB.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    setState(() => _isCompressing = true);

    try {
      final compressed = await ImageCompressor.compress(
        bytes: bytes,
        filename: filename,
        quality: 75,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      final platformFile = PlatformFile(
        name: compressed.filename,
        size: compressed.compressedSize,
        bytes: compressed.bytes,
        path: kIsWeb ? null : path,
      );

      if (mounted) {
        setState(() {
          _attachedFile = platformFile;
        });

        if (compressed.compressionPercentage >= 15.0) {
          final origKb = (compressed.originalSize / 1024).toStringAsFixed(0);
          final compKb = (compressed.compressedSize / 1024).toStringAsFixed(0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imagem otimizada com sucesso: $origKb KB → $compKb KB (-${compressed.compressionPercentage.toStringAsFixed(0)}%)',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF2D6A4F),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao comprimir imagem: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompressing = false);
      }
    }
  }

  /// Trata arquivos soltos via Drag and Drop
  Future<void> _handleDropDone(DropDoneDetails details) async {
    setState(() => _isDragging = false);
    if (details.files.isEmpty) return;

    final dropFile = details.files.first;
    final filename = dropFile.name;

    if (!ImageCompressor.isImageFile(filename)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formato de imagem não suportado. Solte um arquivo PNG, JPG, WEBP, GIF ou BMP.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isCompressing = true);
      final bytes = await dropFile.readAsBytes();

      if (bytes.length > maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O arquivo arrastado excede o limite máximo permitido de 5 MB.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      await _processAndAttachImage(
        bytes: bytes,
        filename: filename,
        path: kIsWeb ? null : dropFile.path,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar imagem arrastada: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompressing = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > maxFileSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O arquivo selecionado excede o limite máximo permitido de 5 MB.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
          return;
        }

        List<int>? rawBytes = file.bytes;
        if (rawBytes == null && !kIsWeb && file.path != null) {
          rawBytes = await File(file.path!).readAsBytes();
        }
        if (rawBytes == null) return;

        if (rawBytes.length > maxFileSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O arquivo selecionado excede o limite máximo permitido de 5 MB.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
          return;
        }

        await _processAndAttachImage(
          bytes: Uint8List.fromList(rawBytes),
          filename: file.name,
          path: kIsWeb ? null : file.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _handleSend() async {
    if (_isUploading || _isCompressing) return;

    final hasText = widget.messageController.text.trim().isNotEmpty;
    final hasAttachment = _attachedFile != null;

    if (!hasText && !hasAttachment) {
      widget.messageFocusNode?.requestFocus();
      return;
    }

    String? uploadedUrl;
    if (_attachedFile != null) {
      if (widget.onUploadMedia != null) {
        setState(() => _isUploading = true);
        try {
          List<int>? bytes = _attachedFile!.bytes;
          if (bytes == null && !kIsWeb && _attachedFile!.path != null) {
            bytes = await File(_attachedFile!.path!).readAsBytes();
          }
          if (bytes != null) {
            if (bytes.length > maxFileSizeBytes) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'O arquivo excede o limite máximo permitido de 5 MB.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
              setState(() => _isUploading = false);
              return;
            }

            uploadedUrl = await widget.onUploadMedia!(
              bytes,
              _attachedFile!.name,
            );
          }

          if (uploadedUrl == null || uploadedUrl.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Falha no upload: o servidor não retornou a URL da imagem.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            }
            setState(() => _isUploading = false);
            return;
          }
        } catch (e) {
          if (mounted) {
            final errorMsg = e.toString().replaceAll('Exception: ', '').trim();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Falha no upload da imagem: $errorMsg'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFEF4444),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          setState(() => _isUploading = false);
          return;
        } finally {
          if (mounted) {
            setState(() => _isUploading = false);
          }
        }
      }
    }

    final fileType = _attachedFile != null
        ? 'image/${_attachedFile!.extension ?? 'png'}'
        : null;

    setState(() {
      _attachedFile = null;
    });

    if (widget.onSendMessageWithMedia != null) {
      widget.onSendMessageWithMedia!(
        widget.channelKey,
        widget.username,
        mediaUrl: uploadedUrl,
        mediaType: fileType,
      );
    } else {
      widget.onSendMessage(widget.channelKey, widget.username);
    }

    widget.messageFocusNode?.requestFocus();
  }

  Future<void> _confirmDelete(BuildContext context, String messageId) async {
    final confirmed = await ConfirmDeleteDialog.show(context);
    if (confirmed == true && mounted) {
      widget.onDeleteMessage(messageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final activeChannelName = widget.activeChannelName;
    final channelKey = widget.channelKey;
    final username = widget.username;
    final messages = widget.messages;
    final messageController = widget.messageController;
    final editMessageController = widget.editMessageController;
    final scrollController = widget.scrollController;
    final messageFocusNode = widget.messageFocusNode;
    final editingMessageId = widget.editingMessageId;
    final isInVoice = widget.isInVoice;
    final accentColor = widget.accentColor;
    final activeBroadcaster = widget.activeBroadcaster;
    final onToggleVoiceChannel = widget.onToggleVoiceChannel;
    final onWatchLive = widget.onWatchLive;
    final onStartEditing = widget.onStartEditing;
    final onCancelEditing = widget.onCancelEditing;
    final onSaveEditing = widget.onSaveEditing;
    final voiceParticipants = widget.voiceParticipants;
    final clientSessionId = widget.clientSessionId;
    final connectedVoiceChannelId = widget.connectedVoiceChannelId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final channelVoiceParticipants =
        voiceParticipants[channelKey]?.values.toList() ??
        <VoiceParticipantInfo>[];

    final isConnectedToThisChannel =
        isInVoice && connectedVoiceChannelId == channelKey;
    final isConnectedToOtherChannel =
        isInVoice &&
        connectedVoiceChannelId != null &&
        connectedVoiceChannelId != channelKey;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: _handleDropDone,
      child: Stack(
        children: [
          Container(
            color: isDark ? const Color(0xFF13141F) : const Color(0xFFFAF9F6),
            child: Column(
              children: [
                // 1. Barra de Participantes em Voz no Canal
                if (channelVoiceParticipants.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F261B)
                          : const Color(0xFFE6F9EE),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${channelVoiceParticipants.length} em call:',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: channelVoiceParticipants.map((p) {
                                final isMe = clientSessionId != null
                                    ? p.sessionId == clientSessionId
                                    : p.username == username;
                                final devLabel = p.device == 'mobile'
                                    ? ' (Celular)'
                                    : p.device == 'desktop'
                                    ? ' (Desktop)'
                                    : '';
                                final pColor = resolveAuthorColor(
                                  p.username,
                                  isDark,
                                );
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1B3828)
                                        : Colors.white,
                                    borderRadius: AppRadius.borderPill,
                                    border: Border.all(
                                      color: const Color(
                                        0xFF22C55E,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: pColor.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            getAuthorInitials(p.username),
                                            style: TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.bold,
                                              color: pColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${p.username}$devLabel${isMe ? " (Você)" : ""}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (p.isDeafened) ...[
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: 'Áudio desativado',
                                          child: Container(
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.18),
                                              borderRadius: AppRadius.borderXs,
                                            ),
                                            child: const Icon(
                                              LucideIcons.headphones,
                                              size: 10,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ] else if (p.isMuted) ...[
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          message: 'Microfone mutado',
                                          child: Container(
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.18),
                                              borderRadius: AppRadius.borderXs,
                                            ),
                                            child: const Icon(
                                              LucideIcons.micOff,
                                              size: 10,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        if (!isConnectedToThisChannel) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: isConnectedToOtherChannel
                                ? 'Mudar voz para #$activeChannelName'
                                : 'Entrar na chamada de voz',
                            child: InkWell(
                              onTap: onToggleVoiceChannel,
                              borderRadius: AppRadius.borderPill,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isConnectedToOtherChannel
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFF22C55E),
                                  borderRadius: AppRadius.borderPill,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isConnectedToOtherChannel
                                          ? LucideIcons.phoneForwarded
                                          : LucideIcons.phoneCall,
                                      size: 11,
                                      color: isConnectedToOtherChannel
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isConnectedToOtherChannel
                                          ? 'Mudar para cá'
                                          : 'Entrar',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isConnectedToOtherChannel
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Sair da chamada de voz',
                            child: InkWell(
                              onTap: onToggleVoiceChannel,
                              borderRadius: AppRadius.borderPill,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.18),
                                  borderRadius: AppRadius.borderPill,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.phoneOff,
                                      size: 11,
                                      color: Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sair',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // 2. Banner de Transmissão Ativa no Canal
                if (activeBroadcaster != null)
                  ActiveLiveStreamBanner(
                    isDark: isDark,
                    broadcaster: activeBroadcaster,
                    onWatchLive: onWatchLive ?? () {},
                  ),

                // 3. Messages List Area
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E2030)
                                        : const Color(0xFFE2E8F0),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.hash,
                                      size: 28,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bem-vindo ao #$activeChannelName!',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Este é o início do canal #$activeChannelName.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Envie uma mensagem abaixo para começar a conversar!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[messages.length - 1 - index];
                            final isEditing = editingMessageId == msg.id;
                            final isMine =
                                msg.author == username || msg.author == 'Você';
                            final initials = getAuthorInitials(msg.author);
                            final authorColor = resolveAuthorColor(
                              msg.author,
                              isDark,
                            );

                            if (isMine) {
                              // MY MESSAGE (WhatsApp Style -> Aligned to the Right)
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Action Icons (Edit / Delete) to the left of the sent bubble
                                    if (!isEditing)
                                      ChatMessageActions(
                                        isDark: isDark,
                                        onEdit: () => onStartEditing(msg.id),
                                        onDelete: () =>
                                            _confirmDelete(context, msg.id),
                                      ),

                                    // WhatsApp Message Bubble
                                    WhatsAppChatBubble(
                                      msg: msg,
                                      isMine: true,
                                      isDark: isDark,
                                      isEditing: isEditing,
                                      isMobile: isMobile,
                                      screenWidth: screenWidth,
                                      accentColor: accentColor,
                                      editController: editMessageController,
                                      onCancelEdit: onCancelEditing,
                                      onSaveEdit: onSaveEditing,
                                    ),
                                    const SizedBox(width: 8),

                                    // Sender Avatar on the Right with Initials
                                    ChatAvatar(
                                      initials: initials,
                                      color: authorColor,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // RECEIVED MESSAGE (From others -> Aligned to the Left)
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Author Avatar on the Left with Initials
                                    ChatAvatar(
                                      initials: initials,
                                      color: authorColor,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(width: 8),

                                    // WhatsApp Message Bubble
                                    WhatsAppChatBubble(
                                      msg: msg,
                                      isMine: false,
                                      isDark: isDark,
                                      isMobile: isMobile,
                                      screenWidth: screenWidth,
                                      authorColor: authorColor,
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                ),

                // 4. Message Input Bar
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    6,
                    20,
                    isMobile
                        ? (MediaQuery.of(context).padding.bottom > 0
                              ? MediaQuery.of(context).padding.bottom + 8.0
                              : 12.0)
                        : 16.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_attachedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2030)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: AppRadius.borderMd,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF313244)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: AppRadius.borderSm,
                                  child: _attachedFile!.bytes != null
                                      ? Image.memory(
                                          Uint8List.fromList(
                                            _attachedFile!.bytes!,
                                          ),
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(LucideIcons.image, size: 24),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 180,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _attachedFile!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        '${(_attachedFile!.size / 1024).toStringAsFixed(1)} KB',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_isUploading || _isCompressing)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  InkWell(
                                    onTap: () =>
                                        setState(() => _attachedFile = null),
                                    borderRadius: AppRadius.borderPill,
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        LucideIcons.x,
                                        size: 15,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2030)
                              : const Color(0xFFFFFFFF),
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2E314A)
                                : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: (_isUploading || _isCompressing)
                                  ? null
                                  : _pickImage,
                              mouseCursor: (_isUploading || _isCompressing)
                                  ? SystemMouseCursors.basic
                                  : SystemMouseCursors.click,
                              borderRadius: AppRadius.borderPill,
                              child: (_isUploading || _isCompressing)
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.plusCircle,
                                      size: 20,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                focusNode: messageFocusNode,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                cursorColor: accentColor,
                                decoration: InputDecoration(
                                  hintText: 'Mensagem em #$activeChannelName',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  isDense: true,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                                onSubmitted: (_) => _handleSend(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {},
                              mouseCursor: SystemMouseCursors.click,
                              borderRadius: AppRadius.borderPill,
                              child: Icon(
                                LucideIcons.smile,
                                size: 20,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: _handleSend,
                              mouseCursor: SystemMouseCursors.click,
                              borderRadius: AppRadius.borderPill,
                              child: Icon(
                                LucideIcons.send,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isDragging) _buildDragOverlay(isDark, accentColor),
        ],
      ),
    );
  }

  /// Overlay visual ativado quando o usuário arrasta uma imagem sobre o chat
  Widget _buildDragOverlay(bool isDark, Color accentColor) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          color: (isDark ? const Color(0xFF13141F) : const Color(0xFFFAF9F6))
              .withValues(alpha: 0.88),
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor, width: 2.5),
              color: accentColor.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.imagePlus,
                      size: 44,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Solte a imagem aqui para anexar',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Formatos suportados: PNG, JPG, WEBP, GIF (compressão automática)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
