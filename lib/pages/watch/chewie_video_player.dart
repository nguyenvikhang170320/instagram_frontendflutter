import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class ChewieVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ChewieVideoPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<ChewieVideoPlayer> createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: true,
            looping: true,
            allowFullScreen: true,
            allowMuting: true,
            showControls: true,
          );
        });
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null
        ? Chewie(controller: _chewieController!)
        : Center(child: CircularProgressIndicator());
  }
}
