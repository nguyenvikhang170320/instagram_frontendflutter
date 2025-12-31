import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoItem extends StatefulWidget {
  final VideoPlayerController controller;
  final String caption;
  final String username;
  final String avatar;

  final int index;
  final int playingIndex;

  final bool isActive; // tab Watch đang active hay không
  final void Function(int index) onRequestPlayIndex;

  const VideoItem({
    super.key,
    required this.controller,
    required this.caption,
    required this.username,
    required this.avatar,
    required this.index,
    required this.playingIndex,
    required this.isActive,
    required this.onRequestPlayIndex,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  bool _showCenterIcon = false;

  void _syncCenterIcon() {
    final shouldShow = !widget.controller.value.isPlaying;
    if (_showCenterIcon != shouldShow) {
      setState(() => _showCenterIcon = shouldShow);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncCenterIcon);
    _showCenterIcon = !widget.controller.value.isPlaying;
  }

  @override
  void didUpdateWidget(covariant VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncCenterIcon);
      widget.controller.addListener(_syncCenterIcon);
      _showCenterIcon = !widget.controller.value.isPlaying;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncCenterIcon);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_${widget.index}'),
      onVisibilityChanged: (info) {
        // LƯU Ý: callback không bắn ngay lập tức, nên chỉ dùng như 1 “gợi ý”
        // và phải chặn theo isActive để tránh auto play khi tab không active.
        final visible = info.visibleFraction > 0.5;

        if (!widget.isActive) {
          if (widget.controller.value.isPlaying) widget.controller.pause();
          return;
        }

        if (visible) {
          if (widget.index != widget.playingIndex) {
            widget.onRequestPlayIndex(widget.index);
          }
        } else {
          if (widget.controller.value.isPlaying) widget.controller.pause();
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

          // play icon overlay (hiện khi đang pause)
          if (_showCenterIcon)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),

          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.avatar.isNotEmpty
                      ? NetworkImage(widget.avatar)
                      : const AssetImage("assets/images/user.jpg")
                  as ImageProvider,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.username.isNotEmpty ? widget.username : "Người dùng",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Text(
              widget.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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
