import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projectnbx/core/network/api_client.dart';

void main() {
  group('ApiClient - Invite Methods', () {
    test('createInvite sends correct payload and returns invite map', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/servers/srv-1/invites');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['max_age_seconds'], 3600);
        expect(body['max_uses'], 5);

        return http.Response(
          jsonEncode({
            'code': 'k9X2mQa',
            'server_id': 'srv-1',
            'max_uses': 5,
            'uses_count': 0,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final invite = await apiClient.createInvite(
        'srv-1',
        maxAgeSeconds: 3600,
        maxUses: 5,
      );

      expect(invite, isNotNull);
      expect(invite!['code'], 'k9X2mQa');
      expect(invite['max_uses'], 5);
    });

    test('getServerInvites returns parsed list of invites', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/servers/srv-1/invites');

        return http.Response(
          jsonEncode([
            {
              'code': 'inv1',
              'server_id': 'srv-1',
              'max_uses': 1,
              'uses_count': 0,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final invites = await apiClient.getServerInvites('srv-1');

      expect(invites.length, 1);
      expect(invites.first['code'], 'inv1');
    });

    test('deleteInvite returns true on 204 or 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/servers/srv-1/invites/inv1');
        return http.Response('', 204);
      });

      final apiClient = ApiClient(client: mockClient);
      final deleted = await apiClient.deleteInvite('srv-1', 'inv1');

      expect(deleted, isTrue);
    });

    test('joinServer joins successfully with invite code', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/servers/k9X2mQa/join');

        return http.Response(
          jsonEncode({'id': 'srv-1', 'name': 'Dev Hub'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final server = await apiClient.joinServer('k9X2mQa');

      expect(server, isNotNull);
      expect(server!['id'], 'srv-1');
      expect(server['name'], 'Dev Hub');
    });

    test('joinServer throws exception on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Código inválido'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      expect(() => apiClient.joinServer('invalid'), throwsA(isA<Exception>()));
    });

    test('createInvite throws exception on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Sem permissão'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient);
      expect(() => apiClient.createInvite('srv-1'), throwsA(isA<Exception>()));
    });

    test(
      'getServerMembers returns member list on success and empty list on error',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('srv-error')) {
            return http.Response('Server Error', 500);
          }
          return http.Response(
            jsonEncode([
              {
                'user_id': 'u1',
                'role': 'owner',
                'user': {'username': 'OwnerUser'},
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(client: mockClient);
        final members = await apiClient.getServerMembers('srv-1');
        expect(members.length, 1);
        expect(members.first['role'], 'owner');

        final emptyMembers = await apiClient.getServerMembers('srv-error');
        expect(emptyMembers, isEmpty);
      },
    );

    test(
      'addServerMember supports username, email, userId and handles error',
      () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['username'] == 'errorUser') {
            return http.Response(
              jsonEncode({'error': 'Usuário não encontrado'}),
              404,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'user_id': 'u2', 'role': 'member'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(client: mockClient);
        final addedByUsername = await apiClient.addServerMember(
          'srv-1',
          username: 'user2',
        );
        expect(addedByUsername, isNotNull);

        final addedByEmail = await apiClient.addServerMember(
          'srv-1',
          email: 'user2@nbx.com',
        );
        expect(addedByEmail, isNotNull);

        final addedById = await apiClient.addServerMember(
          'srv-1',
          userId: 'usr-id-2',
        );
        expect(addedById, isNotNull);

        expect(
          () => apiClient.addServerMember('srv-1', username: 'errorUser'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'removeServerMember returns true on success and false on error',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('err-user')) {
            return http.Response('Not Found', 404);
          }
          return http.Response('', 204);
        });

        final apiClient = ApiClient(client: mockClient);
        final removed = await apiClient.removeServerMember('srv-1', 'u2');
        expect(removed, isTrue);

        final failed = await apiClient.removeServerMember('srv-1', 'err-user');
        expect(failed, isFalse);
      },
    );

    test('getServerInvites returns empty list on network failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Error', 500);
      });

      final apiClient = ApiClient(client: mockClient);
      final invites = await apiClient.getServerInvites('srv-1');
      expect(invites, isEmpty);
    });

    test('deleteInvite returns false on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final apiClient = ApiClient(client: mockClient);
      final deleted = await apiClient.deleteInvite('srv-1', 'inv1');
      expect(deleted, isFalse);
    });

    test(
      'searchUsers returns user list on success and empty list on error',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.queryParameters['q'] == 'empty') {
            return http.Response('Not Found', 404);
          }
          return http.Response(
            jsonEncode([
              {'id': 'u1', 'username': 'SearchDev'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(client: mockClient);
        final results = await apiClient.searchUsers('dev');
        expect(results.length, 1);
        expect(results.first['username'], 'SearchDev');

        final emptyResults = await apiClient.searchUsers('empty');
        expect(emptyResults, isEmpty);
      },
    );
  });
}
