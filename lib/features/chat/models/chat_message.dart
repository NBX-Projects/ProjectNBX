import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String author;
  final Color authorColor;
  final String content;
  final bool isEdited;
  final DateTime? timestamp;

  const ChatMessage({
    required this.id,
    required this.author,
    required this.authorColor,
    required this.content,
    this.isEdited = false,
    this.timestamp,
  });

  /// Converte qualquer string/dado de data (UTC ou local) para DateTime no fuso horário local.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    final str = value.toString().trim();
    if (str.isEmpty) return null;

    var parsed = DateTime.tryParse(str);
    if (parsed == null) return null;

    // Se a string não contiver o sufixo 'Z' nem offset (+/-HH:MM),
    // mas veio do servidor backend que armazena UTC, tratamos como UTC antes do toLocal()
    if (!parsed.isUtc &&
        !str.contains('Z') &&
        !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(str)) {
      parsed = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }
    return parsed.toLocal();
  }

  ChatMessage copyWith({
    String? id,
    String? author,
    Color? authorColor,
    String? content,
    bool? isEdited,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      authorColor: authorColor ?? this.authorColor,
      content: content ?? this.content,
      isEdited: isEdited ?? this.isEdited,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'authorColor': authorColor.toARGB32(),
        'content': content,
        'is_edited': isEdited,
        'timestamp': timestamp?.toUtc().toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ??
            'msg_${json['timestamp'] ?? DateTime.now().microsecondsSinceEpoch}',
        author: json['author'] as String? ?? 'Usuário',
        authorColor: Color(json['authorColor'] as int? ?? 0xFFF5CBA7),
        content: json['content'] as String? ?? '',
        isEdited: json['is_edited'] as bool? ?? false,
        timestamp: parseDateTime(json['timestamp']),
      );

  factory ChatMessage.fromApi(Map<String, dynamic> m, Color defaultColor) {
    var authorName = 'Usuário';
    if (m['author'] is Map) {
      authorName = m['author']['username']?.toString() ?? 'Usuário';
    } else if (m['author_name'] != null &&
        m['author_name'].toString().isNotEmpty) {
      authorName = m['author_name'].toString();
    } else if (m['author'] != null && m['author'].toString().isNotEmpty) {
      authorName = m['author'].toString();
    } else if (m['author_id'] != null && m['author_id'].toString().isNotEmpty) {
      authorName = m['author_id'].toString();
    }

    return ChatMessage(
      id: (m['id'] ?? 'msg_${DateTime.now().microsecondsSinceEpoch}').toString(),
      author: authorName,
      authorColor: defaultColor,
      content: (m['content'] ?? '').toString(),
      isEdited: m['is_edited'] == true,
      timestamp: parseDateTime(m['created_at'] ?? m['timestamp']),
    );
  }
}
