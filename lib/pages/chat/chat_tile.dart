import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần thêm intl vào pubspec.yaml
import '../../model/chat_model.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatTile({
    Key? key,
    required this.chat,
    required this.onTap,
  }) : super(key: key);

  // Hàm format thời gian hiển thị (Vd: 14:30 hoặc Hôm qua)
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && now.day == dt.day) {
      return DateFormat('HH:mm').format(dt);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dt); // Thứ (Mon, Tue...)
    } else {
      return DateFormat('dd/MM').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // AVATAR
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blue[100],
              backgroundImage: (chat.otherUserAvatar.isNotEmpty)
                  ? NetworkImage(chat.otherUserAvatar)
                  : null,
              child: chat.otherUserAvatar.isEmpty
                  ? Text(
                chat.otherUserName.isNotEmpty
                    ? chat.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              )
                  : null,
            ),
            const SizedBox(width: 12),

            // TÊN VÀ TIN NHẮN CUỐI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Đã gửi một ảnh/video',
                    style: TextStyle(
                      fontSize: 14,
                      color: chat.lastMessage.isNotEmpty ? Colors.black54 : Colors.black45,
                      fontStyle: chat.lastMessage.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // THỜI GIAN
            const SizedBox(width: 8),
            Text(
              _formatDateTime(chat.updatedAt), // Sử dụng updatedAt từ Model
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}