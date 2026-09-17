class ServerJoinRequestModel {
  final String id;
  final String serverId;
  final String userId;
  final String? userName;
  final String? userAvatarUrl;
  final String message;
  final String status; // "pending", "approved", "rejected"
  final DateTime createdAt;

  const ServerJoinRequestModel({
    required this.id,
    required this.serverId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    this.message = '',
    required this.status,
    required this.createdAt,
  });

  factory ServerJoinRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ServerJoinRequestModel(
      id: json['id'] as String? ?? '',
      serverId: json['server_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: user?['name'] as String? ?? user?['username'] as String?,
      userAvatarUrl: user?['avatar_url'] as String?,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
