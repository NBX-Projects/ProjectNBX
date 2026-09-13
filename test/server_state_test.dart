import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/features/servers/models/ux_nbx_data.dart';
import 'package:projectnbx/features/servers/models/ux_nbx_models.dart';

void main() {
  group('UX NBX Data & Model Tests', () {
    test('Server and Channel models load correctly', () {
      expect(uxServers.length, 6);
      final apex = uxServers.first;
      expect(apex.name, 'Apex Predators');
      expect(apex.category, 'Gaming');
      expect(apex.memberCount, 847);
      expect(apex.voiceCount, 12);
    });

    test('Channel and message definitions work properly', () {
      expect(uxChannels.length, 4);
      final textVoiceChannel = uxChannels.firstWhere((c) => c.type == ChannelKind.textVoice);
      expect(textVoiceChannel.name, 'geral');
      expect(textVoiceChannel.users.isNotEmpty, true);

      expect(uxMessages.length, 10);
      final firstMsg = uxMessages.first;
      expect(firstMsg.author, 'DarkLord_X');
      expect(firstMsg.content.contains('campeonato'), true);
    });

    test('ChatMessageData copyWith updates reactions', () {
      const msg = ChatMessageData(
        id: 'test_1',
        author: 'Dev',
        initials: 'DV',
        color: Color(0xFF5865F2),
        time: '12:00',
        content: 'Test content',
        isMe: true,
      );

      final updated = msg.copyWith(reactions: {'🔥': 5});
      expect(updated.reactions['🔥'], 5);
      expect(updated.content, 'Test content');
    });
  });
}
