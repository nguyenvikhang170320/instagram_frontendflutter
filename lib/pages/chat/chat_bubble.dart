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
        DateFormat('dd/MM/yyyy HH:mm').format(message.localTimestamp);

    return Column(
      crossAxisAlignment: align,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              message.senderName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
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
      return Text(message.content);
    } else if (message.type == 'image') {
      return Image.network(
        message.mediaUrl ?? '',
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else if (message.type == 'video') {
      return _VideoPlayerWidget(videoUrl: message.mediaUrl ?? '');
    } else {
      return const Text("Không hỗ trợ nội dung này");
    }
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _controller.setLooping(true); // Optional: Loop video
        });
      });
  }

  // Play or Pause the video
  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause(); // Pause video
      } else {
        _controller.play(); // Play video
      }
      _isPlaying = _controller.value.isPlaying;
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              // Add play/pause button below video
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 30,
                  color: Colors.blue,
                ),
                onPressed: _togglePlayPause,
              ),
            ],
          )
        : const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
  }
}
