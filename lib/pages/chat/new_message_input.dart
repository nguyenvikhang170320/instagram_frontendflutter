import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/model/message_model.dart';
import 'package:instagram/services/message_service.dart';

class NewMessageInput extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final List<MessageModel> messages; // Nhận messages từ ChatDetailScreen
  final Function(MessageModel) onMessageSent;

  const NewMessageInput({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.messages,
    required this.onMessageSent,
  });

  @override
  State<NewMessageInput> createState() => _NewMessageInputState();
}

class _NewMessageInputState extends State<NewMessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  void _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      // Gửi tin nhắn với trạng thái "Đã gửi"
      final messageService = MessageService();
      final message = await MessageService.sendMessageAndReturn(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        content: text,
        type: 'text',
      );

      // Làm sạch controller sau khi gửi
      _controller.clear();

      // Cập nhật tin nhắn vào danh sách
      widget.onMessageSent(message);
    } catch (e) {
      print('Lỗi khi gửi tin nhắn: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    final picker = ImagePicker();
    final picked = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);

    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _isSending = true);

    final message = await MessageService.uploadMediaMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      file: file,
      type: isVideo ? 'video' : 'image',
    );

    if (message != null) {
      widget.onMessageSent(message);
    }

    setState(() => _isSending = false);
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Chọn video'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, isVideo: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.camera, isVideo: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: _isSending ? null : _showMediaPicker,
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendTextMessage(),
            decoration: const InputDecoration(
              hintText: 'Nhập tin nhắn...',
            ),
          ),
        ),
        IconButton(
          icon: _isSending
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator())
              : const Icon(Icons.send),
          onPressed: _isSending ? null : _sendTextMessage,
        ),
      ],
    );
  }
}
