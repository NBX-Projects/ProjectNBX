import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Seletor e roteador de viewports de preview/simulação de transmissão
class StreamPreviewViewportSelector extends StatelessWidget {
  final String previewType;
  final String title;
  final Color accentColor;

  const StreamPreviewViewportSelector({
    super.key,
    required this.previewType,
    required this.title,
    this.accentColor = const Color(0xFFF5CBA7),
  });

  @override
  Widget build(BuildContext context) {
    switch (previewType) {
      case 'youtube':
        return YouTubeStreamViewport(title: title);
      case 'android_studio':
        return const AndroidStudioStreamViewport();
      case 'goland':
        return const GoLandStreamViewport();
      case 'figma':
        return FigmaStreamViewport(accentColor: accentColor);
      case 'github':
        return const GitHubStreamViewport();
      case 'whatsapp':
        return const WhatsAppStreamViewport();
      case 'rgb':
        return const RgbStreamViewport();
      case 'vscode':
        return const VsCodeStreamViewport();
      case 'chrome':
        return const ChromeStreamViewport();
      case 'spotify':
        return const SpotifyStreamViewport();
      case 'terminal':
        return const TerminalStreamViewport();
      case 'game':
        return const GameStreamViewport();
      case 'screen1':
      case 'screen2':
        return DesktopMonitorViewport(title: title, accentColor: accentColor);
      case 'discord':
        return const DiscordStreamViewport();
      case 'nbx':
      default:
        return ProjectNbxStreamViewport(accentColor: accentColor);
    }
  }
}

// 1. YouTube Live Stream Viewport
class YouTubeStreamViewport extends StatelessWidget {
  final String title;

  const YouTubeStreamViewport({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [Color(0xFF2A1515), Color(0xFF0A0A0A)],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF0000)
                                  .withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow,
                            size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0000),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AO VIVO',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'YouTube 1080p60 HDR • 48 kHz Stereo Audio',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow,
                            size: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        const Icon(Icons.volume_up,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          '24:10 / 1:12:00',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                width: 220,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Positioned(
                                left: 216,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF0000),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'HD 1080',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.fullscreen,
                            size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Android Studio Stream Viewport
class AndroidStudioStreamViewport extends StatelessWidget {
  const AndroidStudioStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1F22),
      child: Column(
        children: [
          Container(
            height: 36,
            color: const Color(0xFF2B2D30),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.android, size: 16, color: Color(0xFF3DDC84)),
                const SizedBox(width: 8),
                Text('projectNBX — [D:\\Github\\My\\projectNBX]',
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: Colors.white70)),
                const Spacer(),
                const Icon(Icons.play_arrow,
                    size: 16, color: Color(0xFF3DDC84)),
                const SizedBox(width: 8),
                const Icon(Icons.bug_report,
                    size: 16, color: Color(0xFFE8BF6A)),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, size: 16, color: Color(0xFF38BDF8)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 160,
                  color: const Color(0xFF1E1F22),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROJECT',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54)),
                      const SizedBox(height: 8),
                      _buildTreeItem(Icons.folder, 'lib',
                          const Color(0xFF6897BB),
                          isExpanded: true),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTreeItem(Icons.folder, 'features',
                                const Color(0xFF6897BB)),
                            _buildTreeItem(Icons.folder, 'core',
                                const Color(0xFF6897BB)),
                            _buildTreeItem(LucideIcons.fileCode2, 'main.dart',
                                const Color(0xFF3DDC84),
                                isSelected: true),
                          ],
                        ),
                      ),
                      _buildTreeItem(LucideIcons.fileText, 'pubspec.yaml',
                          const Color(0xFFE8BF6A)),
                    ],
                  ),
                ),
                Container(width: 1, color: const Color(0xFF2B2D30)),
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E1F22),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCodeLine('import \'package:flutter/material.dart\';',
                            const Color(0xFFCC7832)),
                        _buildCodeLine(
                            'import \'package:flutter_riverpod/flutter_riverpod.dart\';',
                            const Color(0xFFCC7832)),
                        _buildCodeLine(
                            'import \'package:projectnbx/features/home/screens/home_screen.dart\';',
                            const Color(0xFFCC7832)),
                        _buildCodeLine('', Colors.transparent),
                        _buildCodeLine(
                            'void main() async {', const Color(0xFFFFC66D)),
                        _buildCodeLine(
                            '  WidgetsFlutterBinding.ensureInitialized();',
                            const Color(0xFF9876AA)),
                        _buildCodeLine(
                            '  runApp(const ProviderScope(child: ProjectNBXApp()));',
                            const Color(0xFF9876AA)),
                        _buildCodeLine('}', const Color(0xFFFFC66D)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B2D30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: Color(0xFF3DDC84)),
                              const SizedBox(width: 6),
                              Text(
                                'Running on Windows (Desktop) • Hot Reload active (214ms)',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: const Color(0xFF3DDC84)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 3. GoLand Stream Viewport
class GoLandStreamViewport extends StatelessWidget {
  const GoLandStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1F22),
      child: Column(
        children: [
          Container(
            height: 36,
            color: const Color(0xFF2B2D30),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(LucideIcons.code2,
                    size: 16, color: Color(0xFF00ADD8)),
                const SizedBox(width: 8),
                Text('backend — GoLand 2024.1',
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: Colors.white70)),
                const Spacer(),
                Text('Go 1.22.4',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, color: const Color(0xFF00ADD8))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCodeLine('package database', const Color(0xFFCC7832)),
                  _buildCodeLine('', Colors.transparent),
                  _buildCodeLine(
                      '// ConnectDB establishes high performance pooling with Postgres 16',
                      const Color(0xFF629755)),
                  _buildCodeLine(
                      'func ConnectDB(cfg *config.Config) (*sqlx.DB, error) {',
                      const Color(0xFFFFC66D)),
                  _buildCodeLine(
                      '    db, err := sqlx.Open("postgres", cfg.DatabaseURL)',
                      const Color(0xFF00ADD8)),
                  _buildCodeLine('    if err != nil { return nil, err }',
                      const Color(0xFFCC7832)),
                  _buildCodeLine('    db.SetMaxOpenConns(50)',
                      const Color(0xFF6897BB)),
                  _buildCodeLine('    db.SetMaxIdleConns(10)',
                      const Color(0xFF6897BB)),
                  _buildCodeLine(
                      '    return db, nil', const Color(0xFFCC7832)),
                  _buildCodeLine('}', const Color(0xFFFFC66D)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2D30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check,
                            size: 14, color: Color(0xFF00ADD8)),
                        const SizedBox(width: 6),
                        Text(
                          'Tests passed: 18 of 18 (100% coverage on audit_repository)',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 10, color: const Color(0xFF00ADD8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Figma Stream Viewport
class FigmaStreamViewport extends StatelessWidget {
  final Color accentColor;

  const FigmaStreamViewport(
      {super.key, this.accentColor = const Color(0xFFF5CBA7)});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2C2C),
      child: Column(
        children: [
          Container(
            height: 38,
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(LucideIcons.penTool,
                    size: 16, color: Color(0xFFF24E1E)),
                const SizedBox(width: 8),
                Text('ProjectNBX — Design System 2.0',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0D99FF),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Share',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 140,
                  color: const Color(0xFF252525),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LAYERS',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54)),
                      const SizedBox(height: 8),
                      Text('❖ ScreenShareModal',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFFF24E1E))),
                      Text('  ↳ TopBarHUD',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70)),
                      Text('  ↳ SourceGrid (16:9)',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70)),
                      Text('  ↳ SoundwaveEqualizer',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E1E1E),
                    child: Center(
                      child: Container(
                        width: 320,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF181926),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFF24E1E), width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 20)
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.screenShare,
                                  size: 36, color: accentColor),
                              const SizedBox(height: 8),
                              Text('Discord-Like Screen Share UI',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Text('Real Windows & Monitors Enumerable',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: Colors.white60)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 5. GitHub Desktop Stream Viewport
class GitHubStreamViewport extends StatelessWidget {
  const GitHubStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1F2428),
      child: Column(
        children: [
          Container(
            height: 38,
            color: const Color(0xFF24292E),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(LucideIcons.gitBranch,
                    size: 16, color: Color(0xFF8957E5)),
                const SizedBox(width: 8),
                Text('Current Repository: projectNBX',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(width: 14),
                Text('Current Branch: main',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, color: const Color(0xFF8957E5))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2 changed files in working tree',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileCode2,
                            size: 14, color: Color(0xFF3FB950)),
                        const SizedBox(width: 8),
                        Text(
                            'lib/features/voice/widgets/screen_share_dialog.dart',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, color: Colors.white70)),
                        const Spacer(),
                        Text('+182 -14',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: const Color(0xFF3FB950))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileCode2,
                            size: 14, color: Color(0xFF3FB950)),
                        const SizedBox(width: 8),
                        Text(
                            'lib/features/servers/widgets/server_workspace_view.dart',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, color: Colors.white70)),
                        const Spacer(),
                        Text('+220 -8',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: const Color(0xFF3FB950))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 6. WhatsApp Desktop Stream Viewport
class WhatsAppStreamViewport extends StatelessWidget {
  const WhatsAppStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111B21),
      child: Row(
        children: [
          Container(
            width: 180,
            color: const Color(0xFF202C33),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.messageCircle,
                        size: 18, color: Color(0xFF25D366)),
                    const SizedBox(width: 8),
                    Text('Conversas',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF111B21),
                      borderRadius: BorderRadius.circular(6)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dev Team NBX',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('Transmissão ao vivo iniciada!',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: const Color(0xFF25D366))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF0B141A),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005C4B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'A transmissão via LiveKit está rodando em 1080p 60FPS!',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202C33),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sensacional! A latência está em menos de 20ms.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 7. SignalRGB Chroma Stream Viewport
class RgbStreamViewport extends StatelessWidget {
  const RgbStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF831843),
            Color(0xFF312E81),
            Color(0xFF064E3B),
            Color(0xFF78350F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFFEC4899), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.palette,
                      size: 48, color: Color(0xFFEC4899)),
                  const SizedBox(height: 12),
                  Text('SignalRGB Pro — Chroma Lighting Canvas',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                      'All Peripherals Synchronized to LiveKit Stream Soundwave',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 8. VS Code Stream Viewport
class VsCodeStreamViewport extends StatelessWidget {
  const VsCodeStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Container(
            height: 34,
            color: const Color(0xFF252526),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    border: Border(
                        top: BorderSide(
                            color: Color(0xFF38BDF8), width: 2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileCode2,
                          size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text('server_handler.go',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: const Color(0xFF2D2D2D),
                  child: Text('websocket_client.dart',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, color: Colors.white54)),
                ),
                const Spacer(),
                const Icon(LucideIcons.split, size: 14, color: Colors.white54),
                const SizedBox(width: 8),
                const Icon(LucideIcons.moreHorizontal,
                    size: 14, color: Colors.white54),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFF1E1E1E),
                  child: Column(
                    children: List.generate(
                        16,
                        (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.2),
                              child: Text(
                                '${i + 1}'.padLeft(2, ' '),
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: const Color(0xFF858585)),
                              ),
                            )),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCodeLine(
                            'package handlers', const Color(0xFFC586C0)),
                        _buildCodeLine('', Colors.transparent),
                        _buildCodeLine(
                            '// SendMessage transmits chat and triggers live stream SFU',
                            const Color(0xFF6A9955)),
                        _buildCodeLine(
                            'func (h *ServerHandler) SendMessage(w http.ResponseWriter, r *http.Request) {',
                            const Color(0xFFDCDCAA)),
                        _buildCodeLine('    vars := mux.Vars(r)',
                            const Color(0xFF9CDCFE)),
                        _buildCodeLine('    serverID := vars["id"]',
                            const Color(0xFF9CDCFE)),
                        _buildCodeLine('    channelID := vars["channelId"]',
                            const Color(0xFF9CDCFE)),
                        _buildCodeLine(
                            '    msg := models.NewMessage(serverID, channelID, req.Content)',
                            const Color(0xFF4EC9B0)),
                        _buildCodeLine(
                            '    h.hub.BroadcastEvent(&models.WSEvent{',
                            const Color(0xFFDCDCAA)),
                        _buildCodeLine('        Type: models.EventChatMessage,',
                            const Color(0xFF4FC1FF)),
                        _buildCodeLine('        Payload: msg.ToJSON(),',
                            const Color(0xFFCE9178)),
                        _buildCodeLine('        ChannelID: channelID,',
                            const Color(0xFF9CDCFE)),
                        _buildCodeLine('    })', const Color(0xFFDCDCAA)),
                        _buildCodeLine('    w.WriteHeader(http.StatusCreated)',
                            const Color(0xFF569CD6)),
                        _buildCodeLine('}', const Color(0xFFDCDCAA)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 90,
            color: const Color(0xFF181818),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('TERMINAL',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70)),
                    const SizedBox(width: 8),
                    Text('zsh (ProjectNBX)',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10, color: const Color(0xFF38BDF8))),
                  ],
                ),
                const SizedBox(height: 6),
                Text('➜  projectNBX git:(main) go run ./cmd/api',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5, color: const Color(0xFF4ADE80))),
                Text(
                    '[LiveKit] SFU Room "geral" audio/video track published at 60 FPS (Opus 48kHz)',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: const Color(0xFFF5CBA7))),
                Text('[WS] Hub active • 2 clients connected • Zero frame drops',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: const Color(0xFF38BDF8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 9. Google Chrome Stream Viewport
class ChromeStreamViewport extends StatelessWidget {
  const ChromeStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2028),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF2B2D3A),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2028),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.globe,
                              size: 12, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          Text('LiveKit SFU WebRTC Docs',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2028),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 12, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 6),
                      Text('https://docs.livekit.io/realtime/sfu/performance',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ProjectNBX Ultra-Low Latency Architecture',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                      'Using LiveKit WebRTC SFU with adaptive bitrate (Dynacast), DTX, and Opus 48kHz audio encoding.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildDocCard('SFU Gateway', '12ms Latency',
                          const Color(0xFF38BDF8)),
                      const SizedBox(width: 14),
                      _buildDocCard('Audio Track', '48kHz Opus Stereo',
                          const Color(0xFF4ADE80)),
                      const SizedBox(width: 14),
                      _buildDocCard('Video Track', '1080p 60 FPS VP9',
                          const Color(0xFFF5CBA7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(String title, String subtitle, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF262835),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

// 10. Spotify Stream Viewport
class SpotifyStreamViewport extends StatelessWidget {
  const SpotifyStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F3820), Color(0xFF0A0F0D), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1DB954), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.35),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.music,
                    size: 54, color: Color(0xFF1DB954)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Developer Focus Beats (Lo-Fi)',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('ProjectNBX Live Audio Stream • 48 kHz High Fidelity',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF1DB954))),
            const SizedBox(height: 18),
            SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(18, (i) {
                  final heights = [
                    12, 22, 18, 30, 14, 34, 26, 16, 28, 20, 32, 18, 24, 14,
                    28, 20, 16, 10
                  ];
                  final h = heights[i % heights.length];
                  return Container(
                    width: 4,
                    height: h.toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 11. Windows Terminal Stream Viewport
class TerminalStreamViewport extends StatelessWidget {
  const TerminalStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0C0C),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.squareTerminal,
                  size: 16, color: Color(0xFF4ADE80)),
              const SizedBox(width: 8),
              Text('PowerShell 7.4.2 — ProjectNBX Dev Suite',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, color: Colors.white70)),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          Text('PS D:\\projectNBX> .\\scripts\\deploy_cluster.ps1',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 13, color: const Color(0xFF4ADE80))),
          const SizedBox(height: 8),
          Text('[INFO] Initializing PostgreSQL 16 migration cluster...',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, color: Colors.white60)),
          Text('[INFO] LiveKit SFU running on ${const String.fromEnvironment('LIVEKIT_URL', defaultValue: 'ws://localhost:7880')}',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, color: const Color(0xFF38BDF8))),
          Text('[SUCCESS] WebSocket broadcast stream online on :8080/ws',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, color: const Color(0xFF4ADE80))),
          Text('[ACTIVE] Streaming 1080p 60FPS to channel #geral',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, color: const Color(0xFFF5CBA7))),
        ],
      ),
    );
  }
}

// 12. Game / Racing Simulator Viewport
class GameStreamViewport extends StatelessWidget {
  const GameStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: RacingStreamCanvasPainter()),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('248 KM/H',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFEF4444))),
              Text('GEAR 6 • 8200 RPM',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Container(
                width: 240,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 190,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFFEF4444)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 13. Desktop Monitor Viewport
class DesktopMonitorViewport extends StatelessWidget {
  final String title;
  final Color accentColor;

  const DesktopMonitorViewport({
    super.key,
    required this.title,
    this.accentColor = const Color(0xFFF5CBA7),
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 60,
            left: 50,
            width: 360,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2030),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 20)
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 26,
                    color: const Color(0xFF181926),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text('ProjectNBX Dev Workspace',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(LucideIcons.terminal,
                          size: 36, color: accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 38,
            child: Container(
              color: const Color(0xFF0B0C12),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(LucideIcons.layoutGrid, size: 18, color: accentColor),
                  const SizedBox(width: 14),
                  const Icon(LucideIcons.terminal,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.globe,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.music,
                      size: 16, color: Colors.white70),
                  const Spacer(),
                  Text(
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 14. ProjectNBX Native Stream Viewport
class ProjectNbxStreamViewport extends StatelessWidget {
  final Color accentColor;

  const ProjectNbxStreamViewport(
      {super.key, this.accentColor = const Color(0xFFF5CBA7)});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF141520),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 28)
                ],
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.screenShare, size: 48, color: accentColor),
                  const SizedBox(height: 12),
                  Text('ProjectNBX Live Workspace',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Stream de Alta Performance • Zero Frame Drop',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: accentColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 15. Discord Stream Viewport
class DiscordStreamViewport extends StatelessWidget {
  const DiscordStreamViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF313338),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2D31),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NBX COMMUNITY',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.hash,
                        size: 14, color: Color(0xFF5865F2)),
                    const SizedBox(width: 6),
                    Text('geral',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.volume2,
                        size: 14, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 6),
                    Text('Voz Geral',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF313338),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5865F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.messageSquare,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dev Squad',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('Transmitindo tela com latência de 14ms',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 16. Custom Painter for Game/Racing Stream
class RacingStreamCanvasPainter extends CustomPainter {
  const RacingStreamCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trackPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.12)
      ..strokeWidth = 2;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, size.height * 0.4),
        Offset(i + 120, size.height * 0.9),
        linePaint,
      );
    }

    final kerbPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.72, size.width, 16),
        const Radius.circular(4),
      ),
      kerbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper tree item widget
Widget _buildTreeItem(IconData icon, String name, Color color,
    {bool isExpanded = false, bool isSelected = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          name,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF3DDC84) : Colors.white70,
          ),
        ),
      ],
    ),
  );
}

// Helper code line widget
Widget _buildCodeLine(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.2),
    child: Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    ),
  );
}
