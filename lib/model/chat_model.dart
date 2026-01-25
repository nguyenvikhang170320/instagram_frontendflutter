import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String lastMessage;
  final DateTime updatedAt;

  // Thông tin người chat cùng (Backend đã gộp vào object otherUser)
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  ChatModel({
    required this.chatId,
    required this.lastMessage,
    required this.updatedAt,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Lấy object otherUser từ JSON backend gửi về
    final otherUser = json['otherUser'] ?? {};

    return ChatModel(
      chatId: json['chatId'] ?? '',
      lastMessage: json['lastMessage'] ?? '',

      // Parse thời gian update
      updatedAt: _parseTimestamp(json['updatedAt']),

      // Map thông tin người kia
      otherUserId: otherUser['userId'] ?? '',
      otherUserName: otherUser['username'] ?? 'Người dùng',
      otherUserAvatar: otherUser['avatar'] ?? '',
    );
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    if (ts is Timestamp) return ts.toDate();
    return DateTime.now();
  }
}