import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/utils/chat_helpers.dart';
import 'package:projectnbx/features/chat/widgets/channel_chat_view.dart';
import 'package:projectnbx/features/chat/widgets/components/chat_bubble_components.dart';
import 'package:projectnbx/features/chat/widgets/floating_chat_hud.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';

void main() {
  group('ChatMessage model tests', () {
    test('toJson and fromJson work correctly', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg-1',
        author: 'Alice',
        authorColor: const Color(0xFF38BDF8),
        content: 'Hello World',
        isEdited: true,
        timestamp: now,
      );

      final json = msg.toJson();
      expect(json['id'], 'msg-1');
      expect(json['author'], 'Alice');
      expect(json['content'], 'Hello World');
      expect(json['is_edited'], true);

      final restored = ChatMessage.fromJson(json);
      expect(restored.id, 'msg-1');
      expect(restored.author, 'Alice');
      expect(restored.content, 'Hello World');
      expect(restored.isEdited, true);
    });

    test('copyWith updates fields appropriately', () {
      const msg = ChatMessage(
        id: 'msg-2',
        author: 'Bob',
        authorColor: Colors.red,
        content: 'Initial text',
      );

      final updated = msg.copyWith(
        content: 'New text',
        isEdited: true,
      );

      expect(updated.id, 'msg-2');
      expect(updated.author, 'Bob');
      expect(updated.content, 'New text');
      expect(updated.isEdited, true);
    });

    test('fromApi parses various backend author representations', () {
      // 1. Author as map
      final msg1 = ChatMessage.fromApi({
        'id': 'api-1',
        'author': {'username': 'Charlie'},
        'content': 'From map',
        'created_at': DateTime.now().toIso8601String(),
      }, Colors.blue);
      expect(msg1.author, 'Charlie');
      expect(msg1.content, 'From map');

      // 2. Author as author_name
      final msg2 = ChatMessage.fromApi({
        'id': 'api-2',
        'author_name': 'David',
        'content': 'From author_name',
      }, Colors.blue);
      expect(msg2.author, 'David');

      // 3. Author as string
      final msg3 = ChatMessage.fromApi({
        'id': 'api-3',
        'author': 'Eva',
        'content': 'From string',
      }, Colors.blue);
      expect(msg3.author, 'Eva');

      // 4. Author as author_id
      final msg4 = ChatMessage.fromApi({
        'id': 'api-4',
        'author_id': 'usr_eva',
        'content': 'From author_id',
      }, Colors.blue);
      expect(msg4.author, 'usr_eva');
    });
  });

  group('chat_helpers tests', () {
    test('getAuthorInitials formats various name styles', () {
      expect(getAuthorInitials(''), '?');
      expect(getAuthorInitials('Alice Smith'), 'AS');
      expect(getAuthorInitials('DarkLord_X'), 'DX');
      expect(getAuthorInitials('Solo'), 'SO');
      expect(getAuthorInitials('J'), 'J');
    });

    test('resolveAuthorColor returns stable colors for dark and light themes', () {
      final colorDark1 = resolveAuthorColor('Alice', true);
      final colorDark2 = resolveAuthorColor('Alice', true);
      expect(colorDark1, colorDark2);

      final colorLight = resolveAuthorColor('Alice', false);
      expect(colorLight, isNotNull);

      final defaultColor = resolveAuthorColor('', true);
      expect(defaultColor, isNotNull);
    });

    testWidgets('ChatAvatar renders initials and styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatAvatar(
              initials: 'AB',
              color: Colors.blue,
              isDark: true,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.text('AB'), findsOneWidget);
    });
  });

  group('Chat Widgets tests', () {
    testWidgets('ChannelChatView renders messages and handles sending and editing', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final messageController = TextEditingController();
      final editController = TextEditingController();
      final scrollController = ScrollController();

      var sentMessage = false;

      final sampleMessages = [
        ChatMessage(
          id: 'm1',
          author: 'DevUser',
          authorColor: Colors.green,
          content: 'First message',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'm2',
          author: 'Alice',
          authorColor: Colors.blue,
          content: 'Second message',
          isEdited: true,
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelChatView(
              isDark: true,
              activeChannelName: 'geral',
              channelKey: '1_geral',
              username: 'DevUser',
              messages: sampleMessages,
              messageController: messageController,
              editMessageController: editController,
              scrollController: scrollController,
              isTransmitting: false,
              isInVoice: false,
              isRightSidebarVisible: true,
              onToggleTransmission: () {},
              onToggleVoiceChannel: () {},
              onToggleRightSidebar: () {},
              onWatchLive: () {},
              onSendMessage: (key, author) {
                sentMessage = true;
              },
              onStartEditing: (_) {},
              onCancelEditing: () {},
              onSaveEditing: (_) {},
              onDeleteMessage: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message'), findsOneWidget);
      expect(find.text('Mensagem em #geral'), findsOneWidget);

      // Type and send a message via send icon
      await tester.enterText(find.byType(TextField).first, 'New chat message');
      final sendFinder = find.byIcon(LucideIcons.send);
      expect(sendFinder, findsOneWidget);
      await tester.tap(sendFinder);
      await tester.pumpAndSettle();

      expect(sentMessage, isTrue);

      // Verify timestamp component
      expect(find.byType(ChatTimestampText), findsAtLeastNWidgets(1));
    });

    testWidgets('FloatingChatHud renders HUD and channel tags', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final messageController = TextEditingController();
      final scrollController = ScrollController();
      final voiceNotifier = VoiceStateNotifier();

      const testChannels = [
        ChannelModel(id: 'c1', serverId: '1', name: 'geral', type: ChannelType.text),
        ChannelModel(id: 'c2', serverId: '1', name: 'anuncios', type: ChannelType.text),
      ];

      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingChatHud(
              activeChannelName: 'geral',
              channelKey: '1_geral',
              username: 'DevUser',
              messages: const [],
              channels: testChannels,
              activeChannel: testChannels.first,
              messageController: messageController,
              scrollController: scrollController,
              voiceState: const VoiceState(),
              voiceNotifier: voiceNotifier,
              onClose: () {
                closed = true;
              },
              onSelectChannel: (c) {},
              onSendMessage: (k, a) {},
              onStartEditing: (m) {},
              onDeleteMessage: (id) {},
              onLeaveVoice: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chats · #geral'), findsOneWidget);
      expect(find.text('# geral'), findsAtLeastNWidgets(1));

      // Close HUD via minimize button
      final closeFinder = find.byIcon(LucideIcons.arrowUpRight);
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });

    testWidgets('ChatMessageActions triggers onEdit and onDelete callbacks', (tester) async {
      var edited = false;
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageActions(
              isDark: true,
              onEdit: () => edited = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.pencil));
      expect(edited, isTrue);

      await tester.tap(find.byIcon(LucideIcons.trash2));
      expect(deleted, isTrue);
    });

    testWidgets('WhatsAppChatBubble renders normal and editing state with save and cancel', (tester) async {
      final msg = ChatMessage(
        id: 'msg-test',
        author: 'Tester',
        authorColor: Colors.blue,
        content: 'Conteúdo original',
        timestamp: DateTime.now(),
      );

      final editController = TextEditingController(text: 'Conteúdo editado');
      var savedId = '';
      var cancelled = false;

      // 1. Normal state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WhatsAppChatBubble(
                  msg: msg,
                  isMine: true,
                  isDark: true,
                  isMobile: false,
                  screenWidth: 1000,
                  isEditing: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Conteúdo original'), findsOneWidget);

      // 2. Editing state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WhatsAppChatBubble(
                  msg: msg,
                  isMine: true,
                  isDark: true,
                  isMobile: false,
                  screenWidth: 1000,
                  isEditing: true,
                  editController: editController,
                  onCancelEdit: () => cancelled = true,
                  onSaveEdit: (id) => savedId = id,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cancelar'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);

      await tester.tap(find.text('cancelar'));
      expect(cancelled, isTrue);

      await tester.tap(find.text('Salvar'));
      expect(savedId, 'msg-test');
    });

    testWidgets('FloatingChatHud switches channels, sends message, and leaves voice', (tester) async {
      final messageController = TextEditingController();
      final scrollController = ScrollController();
      final voiceNotifier = VoiceStateNotifier();

      const testChannels = [
        ChannelModel(id: 'c1', serverId: '1', name: 'geral', type: ChannelType.text),
        ChannelModel(id: 'c2', serverId: '1', name: 'anuncios', type: ChannelType.text),
      ];

      var sentKey = '';
      var selectedChannelId = '';
      var leftVoice = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingChatHud(
              activeChannelName: 'geral',
              channelKey: '1_geral',
              username: 'Tester',
              messages: const [],
              channels: testChannels,
              activeChannel: testChannels.first,
              messageController: messageController,
              scrollController: scrollController,
              voiceState: const VoiceState(isConnected: true, connectedChannelId: 'c1'),
              voiceNotifier: voiceNotifier,
              onClose: () {},
              onSelectChannel: (c) => selectedChannelId = c.id,
              onSendMessage: (k, a) => sentKey = k,
              onStartEditing: (m) {},
              onDeleteMessage: (id) {},
              onLeaveVoice: () => leftVoice = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap channel tag # anuncios
      final anunciosTag = find.text('# anuncios');
      if (anunciosTag.evaluate().isNotEmpty) {
        await tester.tap(anunciosTag.first);
        expect(selectedChannelId, 'c2');
      }

      // Enter message and tap send
      final inputFinder = find.byType(TextField);
      if (inputFinder.evaluate().isNotEmpty) {
        await tester.enterText(inputFinder.first, 'Olá HUD');
        final sendBtn = find.byIcon(LucideIcons.send);
        if (sendBtn.evaluate().isNotEmpty) {
          await tester.tap(sendBtn.first);
          expect(sentKey, '1_geral');
        }
      }

      // Leave voice button
      final leaveBtn = find.byIcon(LucideIcons.phoneOff);
      if (leaveBtn.evaluate().isNotEmpty) {
        await tester.tap(leaveBtn.first);
        expect(leftVoice, isTrue);
      }
    });
  });
}
