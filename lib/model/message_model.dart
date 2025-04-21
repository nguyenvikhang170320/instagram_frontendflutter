import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? mediaUrl;
  final String status; // sent, delivered, seen
  final String type; // text, image, video
  final String senderName;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    this.mediaUrl,
    required this.status,
    required this.type,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      status: json['status'] ?? 'sent',
      type: json['type'] ?? 'text',
      timestamp: _parseTimestamp(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'mediaUrl': mediaUrl,
      'status': status,
      'type': type,
      'createdAt': timestamp.toIso8601String(),
    };
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    if (ts is DateTime) return ts;
    if (ts is Timestamp)
      return ts.toDate(); // Fix Firestore Timestamp to DateTime
    if (ts is Map && ts.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(ts['_seconds'] * 1000);
    }
    return DateTime.now();
  }

  // Convert timestamp to local time
  DateTime get localTimestamp => timestamp.toLocal();
}
