import 'package:flutter/material.dart';
import 'package:instagram/provider/notification_provider.dart';
import 'package:instagram/sharepreference/sharepre.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchNotifications();
  }

  void _loadUserIdAndFetchNotifications() async {
    String? userId = await getUserId(); // Lấy userId từ SharedPreferences

    if (userId != null) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.fetchNotifications(userId);
      await notificationProvider.fetchUnreadNotifications(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thông báo")),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return ListView.builder(
            itemCount: notificationProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];

              String userName = notification.userName;
              String notificationText = getNotificationText(notification.type);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: notification.avatar.isNotEmpty
                      ? NetworkImage(notification.avatar)
                      : null,
                  child:
                      notification.avatar.isEmpty ? Icon(Icons.person) : null,
                ),
                title: Text("${notification.userName} $notificationText"),
              );
            },
          );
        },
      ),
    );
  }

  String getNotificationText(String type) {
    switch (type) {
      case 'like':
        return 'đã thích ảnh của bạn';
      case 'comment':
        return 'đã bình luận về bài viết của bạn';
      case 'share_post':
        return 'vừa chia sẻ bài viết của bạn';
      case 'upload_post':
        return 'đã chia sẻ một bài viết mới';
      case 'save':
        return 'đã lưu một bài viết mới';
      default:
        return '';
    }
  }
}
