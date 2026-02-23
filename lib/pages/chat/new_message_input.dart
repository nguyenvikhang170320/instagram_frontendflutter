import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../provider/chat_provider.dart';


class NewMessageInput extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const NewMessageInput({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<NewMessageInput> createState() => _NewMessageInputState();
}

class _NewMessageInputState extends State<NewMessageInput> {
  final TextEditingController _controller = TextEditingController();

  // ===============================
  // SEND TEXT
  // ===============================
  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    await context.read<ChatProvider>().sendTextMessage(
      chatId: widget.chatId,
      text: text,
      currentUserId: widget.currentUserId,
    );

  }

  // ===============================
  // SEND MEDIA
  // ===============================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    await context.read<ChatProvider>().sendMediaMessage(
      chatId: widget.chatId,
      filePath: File(picked.path),

      currentUserId: widget.currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSending = context.watch<ChatProvider>().isSending;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.image),
          onPressed: isSending ? null : _pickImage,
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendText(),
            decoration: const InputDecoration(
              hintText: 'Nhập tin nhắn...',
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: isSending
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.send),
          onPressed: isSending ? null : _sendText,
        ),
      ],
    );
  }
}
