import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> members;
  final String otherUserId;
  final String otherUserName; // Thêm trường này
  final String senderName; // Thêm trường này
  final String? lastMessage;
  final DateTime? updatedAt;

  ChatModel({
    required this.chatId,
    required this.members,
    required this.otherUserId,
    required this.otherUserName, // Thêm trường này
    required this.senderName, // Thêm trường này
    this.lastMessage,
    this.updatedAt,
  });

  factory ChatModel.fromMap(
      String id, Map<String, dynamic> data, String currentUserId) {
    List<String> members = List<String>.from(data['members']);
    String otherId = members.firstWhere((id) => id != currentUserId);
    return ChatModel(
      chatId: id,
      members: members,
      otherUserId: otherId,
      otherUserName:
          data['otherUserName'] ?? "User $otherId", // Thêm trường này
      senderName: data['senderName'] ?? 'Người dùng', // Thêm trường này
      lastMessage: data['lastMessage'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  String get lastMessageTimeFormatted {
    if (updatedAt == null) return "";
    return "${updatedAt!.day.toString().padLeft(2, '0')}/"
        "${updatedAt!.month.toString().padLeft(2, '0')}/"
        "${updatedAt!.year} lúc ${updatedAt!.hour.toString().padLeft(2, '0')}:"
        "${updatedAt!.minute.toString().padLeft(2, '0')}";
  }
}
