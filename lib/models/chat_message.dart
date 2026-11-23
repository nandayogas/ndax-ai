class ChatMessage {
  final int? id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    'role': role,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
    id: map['id'] as int?,
    role: map['role'] as String,
    content: map['content'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
