import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instagram/model/message_model.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? Colors.blue[100] : Colors.grey[300];
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.circular(12);
    String formattedTime =
        DateFormat('dd/MM/yyyy HH:mm').format(message.createdAt);

    return Column(
      crossAxisAlignment: align,
      children: [
        // PHẦN NỘI DUNG TIN NHẮN
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
          ),
          child: _buildMessageContent(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            formattedTime,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent() {
    if (message.type == 'text') {
      return Text(message.text ?? '');
    }

    if (message.type == 'image') {
      // ✅ Có URL từ backend
      if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
        return Image.network(
          message.mediaUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image),
        );
      }

      // ✅ Ảnh local (optimistic UI)
      if (message.localImagePath != null) {
        return Image.file(
          File(message.localImagePath!),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        );
      }
      print('TYPE: ${message.type}');
      print('MEDIA URL: ${message.mediaUrl}');
      print('LOCAL PATH: ${message.localImagePath}');
      // ❌ fallback
      return const Icon(Icons.image_not_supported);
    }

    return const Text("Không hỗ trợ nội dung này");
  }

}

