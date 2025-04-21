import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPreview extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerPreview({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  _VideoPlayerPreviewState createState() => _VideoPlayerPreviewState();
}

class _VideoPlayerPreviewState extends State<VideoPlayerPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
}
