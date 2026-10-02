class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final String messageType; // 'text', 'system', 'action_meeting', 'action_completed'
  final DateTime? readAt;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    this.messageType = 'text',
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType,
    };
  }
}
