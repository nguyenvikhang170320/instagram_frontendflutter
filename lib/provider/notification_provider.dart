import 'package:flutter/foundation.dart';
import 'package:instagram/model/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  bool loading = false;
  String? error;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((n) => (n.seen == false)).length;

  Future<void> fetchNotifications() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _service.fetchMyNotifications();
      _notifications =
          data.map((e) => NotificationModel.fromMap(e)).toList();
    } catch (e) {
      error = e.toString(); // ✅ không throw để khỏi crash [web:869]
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createNotification({
    required String receiverId,
    required String type,
    String? postId,
    String? message,
  }) async {
    try {
      await _service.createNotification(
        receiverId: receiverId,
        type: type,
        postId: postId,
        message: message,
      );
      await fetchNotifications();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);

      // optimistic local update
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(seen: true);
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
