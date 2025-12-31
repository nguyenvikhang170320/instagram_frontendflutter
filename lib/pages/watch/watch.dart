import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/pages/watch/chewie_video_player.dart';
import 'package:instagram/pages/watch/video_item.dart';
import 'package:instagram/provider/watch_provider.dart';
import 'package:provider/provider.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';
import 'package:video_player/video_player.dart';

class WatchScreen extends StatefulWidget {
  final bool isActive; // BottomNav truyền vào: _selectedIndex == 3
  const WatchScreen({super.key, required this.isActive});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final ImagePicker _picker = ImagePicker();

  final List<VideoPlayerController> controllers = [];
  int playingIndex = 0;
  bool controllersReady = false;

  bool _pendingAutoPlay = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _load();
      // Không auto-play ở đây.
    });
  }

  @override
  void didUpdateWidget(covariant WatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // rời tab Watch
    if (oldWidget.isActive && !widget.isActive) {
      pauseAll();
    }

    // vào tab Watch
    if (!oldWidget.isActive && widget.isActive) {
      if (controllersReady && controllers.isNotEmpty) {
        resumeCurrent();
      } else {
        _pendingAutoPlay = true;
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void pauseAll() {
    for (final c in controllers) {
      if (c.value.isPlaying) c.pause();
    }
  }

  void resumeCurrent() {
    if (!controllersReady || controllers.isEmpty) return;
    if (playingIndex >= controllers.length) return;
    controllers[playingIndex].play();
  }

  Future<void> _load() async {
    await context.read<WatchProvider>().fetchAllVideos();
    if (!mounted) return;
    await _rebuildControllers();
  }

  Future<void> _rebuildControllers() async {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
    playingIndex = 0;
    controllersReady = false;
    if (mounted) setState(() {});

    final urls = context.read<WatchProvider>().videoUrls;

    for (final url in urls) {
      if (url.isEmpty) continue;
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      c.setLooping(true);
      controllers.add(c);
    }

    // Không auto-play
    if (controllers.isNotEmpty) {
      controllers[0].pause();
    }

    controllersReady = true;
    if (mounted) setState(() {});

    // nếu tab Watch đang active và trước đó đang "đợi" play
    if (widget.isActive && _pendingAutoPlay) {
      _pendingAutoPlay = false;
      resumeCurrent();
    }
  }

  void _playIndex(int index) {
    if (index >= controllers.length) return;

    if (playingIndex < controllers.length) {
      controllers[playingIndex].pause();
    }
    playingIndex = index;

    if (widget.isActive) {
      controllers[playingIndex].play();
    }
    if (mounted) setState(() {});
  }

  void _onPageChanged(int index) => _playIndex(index);

  void _togglePlayPause() {
    if (!widget.isActive) return;
    if (!controllersReady || controllers.isEmpty) return;
    if (playingIndex >= controllers.length) return;

    final c = controllers[playingIndex];
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final file = File(video.path);
    if (!await file.exists()) return;

    final caption = await _showCaptionDialog(context);
    if (caption == null) return;

    final ok = await context.read<WatchProvider>().uploadVideo(
      filePath: file.path,
      caption: caption,
    );

    if (!mounted) return;

    if (!ok) {
      final err = context.read<WatchProvider>().error ?? "Upload thất bại";
      ToastService.showErrorToast(
        context,
        length: ToastLength.medium,
        expandedHeight: 100,
        message: err,
      );
      return;
    }

    await context.read<WatchProvider>().fetchAllVideos();
    if (!mounted) return;
    await _rebuildControllers();
  }

  Future<String?> _showCaptionDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nhập mô tả video"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nhập caption..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WatchProvider>();
    final videos = wp.videos;

    return Scaffold(
      backgroundColor: Colors.black,
      body: wp.loading || !controllersReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, index) {
              final ready = index < controllers.length &&
                  controllers[index].value.isInitialized;

              if (!ready) {
                return const Center(child: CircularProgressIndicator());
              }

              final videoUrl = (videos[index]['videoUrl'] ?? '').toString();

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                onDoubleTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        body: Center(
                          child: ChewieVideoPlayer(videoUrl: videoUrl),
                        ),
                      ),
                    ),
                  );
                },
                child: VideoItem(
                  controller: controllers[index],
                  caption: (videos[index]['caption'] ?? '').toString(),
                  username: (videos[index]['username'] ?? '').toString(),
                  avatar: (videos[index]['avatar'] ?? '').toString(),
                  index: index,
                  playingIndex: playingIndex,
                  isActive: widget.isActive,
                  onRequestPlayIndex: _playIndex,
                ),
              );
            },
          ),
          Positioned(
            bottom: 50,
            right: 20,
            child: FloatingActionButton(
              onPressed: _pickVideo,
              backgroundColor: Colors.pinkAccent,
              child: const Icon(Icons.add, size: 30, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
