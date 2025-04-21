import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String senderId;
  final String type;
  final String postId;
  final Timestamp timestamp;
  bool seen;
  final String userName;
  final String avatar; // nếu có

  NotificationModel({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.type,
    required this.postId,
    required this.timestamp,
    required this.seen,
    required this.userName,
    required this.avatar,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'],
      userId: data['userId'],
      senderId: data['senderId'],
      type: data['type'],
      postId: data['postId'] ?? '',
      seen: data['seen'] ?? false,
      userName: data['userName'] ?? 'Người dùng',
      avatar: data['avatar'] ?? '',
      timestamp: _convertToTimestamp(data['timestamp']),
    );
  }
  static Timestamp _convertToTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value;
    } else if (value is Map<String, dynamic> && value.containsKey('seconds')) {
      return Timestamp.fromMillisecondsSinceEpoch(
          (value['seconds'] * 1000).toInt());
    } else {
      return Timestamp.now(); // fallback nếu dữ liệu sai
    }
  }
}
