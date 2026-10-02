import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justtalking/features/servers/models/channel_model.dart';
import 'package:justtalking/features/servers/widgets/home_sections/server_active_call_banner.dart';
import 'package:justtalking/features/voice/models/voice_participant_info.dart';

void main() {
  const channelGeral = ChannelModel(
    id: 'c1',
    serverId: 's1',
    name: 'geral',
    type: ChannelType.voice,
  );

  const channelVozGeral = ChannelModel(
    id: 'c2',
    serverId: 's1',
    name: 'Voz Geral',
    type: ChannelType.voice,
  );

  testWidgets(
    'ServerActiveCallBanner renders multiple simultaneous calls across different channels',
    (tester) async {
      final now = DateTime.now();
      final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants = {
        'c1': {
          'u1': VoiceParticipantInfo(
            sessionId: 'sess-1',
            userId: 'u1',
            serverId: 's1',
            channelId: 'c1',
            username: 'Sr. SixSeven',
            isInVoice: true,
            isTransmitting: true,
            updatedAt: now,
          ),
        },
        'c2': {
          'u2': VoiceParticipantInfo(
            sessionId: 'sess-2',
            userId: 'u2',
            serverId: 's1',
            channelId: 'c2',
            username: 'jb',
            isInVoice: true,
            isTransmitting: false,
            updatedAt: now,
          ),
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerActiveCallBanner(
              isDark: true,
              channels: const [channelGeral, channelVozGeral],
              voiceParticipants: voiceParticipants,
              onOpenChannel: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Ambos os canais ativos devem ser exibidos simultaneamente
      expect(find.text('TRANSMISSÃO AO VIVO'), findsOneWidget);
      expect(find.text('geral'), findsOneWidget);
      expect(find.text('Sr. SixSeven (Ao vivo)'), findsOneWidget);

      expect(find.text('CHAMADA EM ANDAMENTO'), findsOneWidget);
      expect(find.text('Voz Geral'), findsOneWidget);
      expect(find.text('jb'), findsOneWidget);
    },
  );
}
