class ServerRoleModel {
  final String id;
  final String serverId;
  final String name;
  final int color;
  final int position;
  final Map<String, bool> permissions;

  const ServerRoleModel({
    required this.id,
    required this.serverId,
    required this.name,
    this.color = 0xFFF5CBA7,
    this.position = 0,
    this.permissions = const {},
  });

  bool get canAcceptJoinRequests =>
      permissions['can_accept_join_requests'] ?? false;
  bool get canManageRoles => permissions['can_manage_roles'] ?? false;

  factory ServerRoleModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as Map<String, dynamic>? ?? {};
    final perms = rawPerms.map((k, v) => MapEntry(k, v == true));
    return ServerRoleModel(
      id: json['id'] as String? ?? '',
      serverId: json['server_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as int? ?? 0xFFF5CBA7,
      position: json['position'] as int? ?? 0,
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'color': color,
      'position': position,
      'permissions': permissions,
    };
  }
}
