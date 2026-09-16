class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String status;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    this.name = '',
    required this.username,
    required this.email,
    this.status = 'online',
    this.avatarUrl,
  });

  String get displayName => name.trim().isNotEmpty ? name : username;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    return UserModel(
      id: json['id'] as String? ?? '',
      name: name.isNotEmpty ? name : username,
      username: username,
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'online',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? status,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'status': status,
      'avatar_url': avatarUrl,
    };
  }
}

class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
