import 'package:projectnbx/features/servers/models/server_model.dart';

class PublicServerModel {
  final ServerModel server;
  final bool isMember;
  final String joinRequestStatus; // "none", "pending", "approved", "rejected"

  const PublicServerModel({
    required this.server,
    required this.isMember,
    required this.joinRequestStatus,
  });

  factory PublicServerModel.fromJson(Map<String, dynamic> json) {
    return PublicServerModel(
      server: ServerModel.fromJson(json),
      isMember: json['is_member'] as bool? ?? false,
      joinRequestStatus: json['join_request_status'] as String? ?? 'none',
    );
  }
}
