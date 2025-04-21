import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoItem extends StatefulWidget {
  final VideoPlayerController controller;
  final String caption;
  final int index;
  final int? playingIndex;
  final Function(int) onTapPlay;

  const VideoItem({
    Key? key,
    required this.controller,
    required this.caption,
    required this.index,
    required this.playingIndex,
    required this.onTapPlay,
  }) : super(key: key);

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.index.toString()),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0.5;
        if (visible) {
          if (widget.index != widget.playingIndex) {
            widget.onTapPlay(widget.index); // play
          }
        } else {
          if (widget.controller.value.isPlaying) {
            widget.controller.pause(); // pause
          }
        }
      },
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            child: Text(
              widget.caption,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
