import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/providers/server_provider.dart';

void main() {
  group('Server and Channel Model Tests', () {
    test('Channel creation and copyWith works as expected', () {
      const channel = Channel(
        id: 'c-test',
        name: 'test-topic',
        tag: 'DEVELOPMENT',
        activeVoiceCount: 2,
        hasActiveScreenShare: true,
      );

      expect(channel.id, 'c-test');
      expect(channel.name, 'test-topic');
      expect(channel.activeVoiceCount, 2);
      expect(channel.hasActiveScreenShare, true);

      final updated = channel.copyWith(activeVoiceCount: 5, unreadCount: 3);
      expect(updated.activeVoiceCount, 5);
      expect(updated.unreadCount, 3);
      expect(updated.name, 'test-topic');
    });

    test('ServerNotifier navigation and message dispatch works', () {
      final notifier = ServerNotifier();

      // Initial state
      expect(notifier.state.viewMode, ViewMode.homeDashboard);
      expect(notifier.state.servers.isNotEmpty, true);

      // Navigate to Hub
      final targetServer = notifier.state.servers[1];
      notifier.selectServer(targetServer);

      expect(notifier.state.viewMode, ViewMode.hubWorkspace);
      expect(notifier.state.selectedServer.id, targetServer.id);

      // Toggle Command Palette
      notifier.toggleCommandPalette(true);
      expect(notifier.state.showCommandPalette, true);
      notifier.toggleCommandPalette(false);
      expect(notifier.state.showCommandPalette, false);

      // Send chat message
      final selectedChannelId = notifier.state.selectedChannel.id;
      final initialCount = notifier.state.channelMessages[selectedChannelId]?.length ?? 0;

      notifier.sendMessage('Hello from automated test!');
      final newCount = notifier.state.channelMessages[selectedChannelId]?.length ?? 0;
      expect(newCount, initialCount + 1);

      final lastMsg = notifier.state.channelMessages[selectedChannelId]!.last;
      expect(lastMsg.content, 'Hello from automated test!');
      expect(lastMsg.isCurrentUser, true);
    });
  });
}
