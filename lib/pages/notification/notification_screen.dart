import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:instagram/provider/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<NotificationProvider>().fetchNotifications();
      // nếu muốn mark all read thì tự làm trong provider (loop markRead), hoặc bỏ
    }); // postFrameCallback pattern [web:384]
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, np, _) {
          if (np.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (np.error != null) {
            return Center(child: Text(np.error!));
          }
          if (np.notifications.isEmpty) {
            return const Center(child: Text("Chưa có thông báo"));
          }

          return ListView.builder(
            itemCount: np.notifications.length,
            itemBuilder: (_, index) {
              final n = np.notifications[index];
              final text = _getNotificationText(n.type);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  n.avatar.isNotEmpty ? NetworkImage(n.avatar) : null,
                  child: n.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text("${n.userName} $text"),
                onTap: () async {
                  // mark read 1 cái (nếu chưa đọc)
                  if (n.seen == false) {
                    await context.read<NotificationProvider>().markRead(n.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getNotificationText(String type) {
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
      case 'follow':
        return 'đã theo dõi bạn';
      default:
        return '';
    }
  }
}
