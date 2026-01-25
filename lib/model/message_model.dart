import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;    // ✅ Cần thêm cái này
  final String senderId;
  final String text;      // ✅ Backend trả về 'text', không phải 'content'
  final String type;      // text, image, video (mặc định 'text')
  final DateTime createdAt;

  // Các trường mở rộng (Optional - Backend chưa có nhưng cứ để chờ nâng cấp)
  final String? mediaUrl;
  final String status;    // sent, seen

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = 'text',
    this.mediaUrl,
    this.status = 'sent',
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '', // Backend Mongo/Node thường trả về _id
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? json['content'] ?? '', // Fallback nếu bạn đổi ý bên backend

      // Timestamp từ Node.js thường là String ISO
      createdAt: _parseTimestamp(json['createdAt']),

      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      status: json['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Hàm xử lý thời gian đa năng (String ISO, Timestamp, Date...)
  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();

    // Node.js trả về chuỗi ISO 8601 (ví dụ: "2023-10-01T12:00:00Z")
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();

    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;

    return DateTime.now();
  }
}