import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;

  // backend dùng receiverId, bạn đang gọi là userId -> giữ userId cho UI
  final String userId;     // receiverId
  final String senderId;

  final String type;
  final String postId;

  final Timestamp timestamp;

  // backend dùng isRead, bạn đang dùng seen -> giữ seen cho UI
  final bool seen;

  // backend trả senderName/senderAvatar
  final String userName;
  final String avatar;

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

  NotificationModel copyWith({
    bool? seen,
    Timestamp? timestamp,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      senderId: senderId,
      type: type,
      postId: postId,
      timestamp: timestamp ?? this.timestamp,
      seen: seen ?? this.seen,
      userName: userName,
      avatar: avatar,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: (data['id'] ?? '').toString(),

      // support both receiverId (backend) and userId (old)
      userId: (data['receiverId'] ?? data['userId'] ?? '').toString(),

      senderId: (data['senderId'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      postId: (data['postId'] ?? '').toString(),

      // support both isRead (backend) and seen (old)
      // UI: seen=true nghĩa là đã đọc
      seen: (data['isRead'] ?? data['seen'] ?? false) == true,

      // support both senderName/senderAvatar (backend) and userName/avatar (old)
      userName: (data['senderName'] ?? data['userName'] ?? 'Người dùng').toString(),
      avatar: (data['senderAvatar'] ?? data['avatar'] ?? '').toString(),

      // backend: createdAt ISO string; firestore: timestamp Timestamp
      timestamp: _parseToTimestamp(data['createdAt'] ?? data['timestamp']),
    );
  }

  static Timestamp _parseToTimestamp(dynamic value) {
    if (value is Timestamp) return value;

    // backend createdAt: "2025-12-31T..." (ISO string)
    if (value is String && value.isNotEmpty) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return Timestamp.fromDate(dt.toLocal());
    }

    // firestore map {seconds:..., nanoseconds:...}
    if (value is Map && value['seconds'] != null) {
      final seconds = (value['seconds'] as num).toInt();
      return Timestamp.fromMillisecondsSinceEpoch(seconds * 1000);
    }

    return Timestamp.now();
  }
}
