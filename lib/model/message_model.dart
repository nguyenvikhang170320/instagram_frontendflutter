class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String type; // text | image | video
  final String? mediaUrl;
  final String? localImagePath;
  final DateTime createdAt;
  final String status;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    this.mediaUrl,
    this.localImagePath,
    required this.createdAt,
    this.status = 'sent',
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? json['_id'] ?? '',
      chatId: json['chatId'],
      senderId: json['senderId'],
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      status: json['status'] ?? 'sent',
    );
  }
}
