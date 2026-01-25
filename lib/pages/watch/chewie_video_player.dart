import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:toasty_box/toast_service.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../provider/watch_provider.dart';

class ChewieVideoPlayer extends StatefulWidget {
  final String videoId; // Thêm biến này
  final String videoUrl; // Thêm biến này
  const ChewieVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.videoId // Yêu cầu truyền id vào
  }) : super(key: key);

  @override
  State<ChewieVideoPlayer> createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowMuting: true,
        showControls: true,
        // Tùy chọn này quan trọng để tránh lỗi khi seek
          // chewie_video_player.dart
        progressIndicatorDelay: (!kIsWeb && Platform.isAndroid)
              ? const Duration(days: 1)  // Tắt spinner hiệu (nhưng vẫn play bình)
              : null,
        placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (context, errorMessage) {
          return Center(child: Text("Lỗi: $errorMessage", style: const TextStyle(color: Colors.white)));
        },
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading chewie: $e");
    }
  }
// Hàm xử lý xóa
  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa video này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Xóa", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Gọi hàm xóa từ Provider
      final success = await context.read<WatchProvider>().deleteVideo(widget.videoId);

      if (context.mounted) {
        if (success) {
          ToastService.showSuccessToast(context, message: "Đã xóa video thành công");
          Navigator.pop(context); // Quay lại trang Profile
        } else {
          String errorMsg = context.read<WatchProvider>().error ?? "Lỗi khi xóa";
          ToastService.showErrorToast(context, message: errorMsg);
        }
      }
    }
  }
  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Phần hiển thị Video
            Center(
              child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // Nút Quay lại (Góc trái)
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Nhóm nút chức năng: Xóa & Ba chấm (Góc phải)
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  // 1. Icon Xóa
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                    onPressed: () => _confirmDelete(context),
                  ),

                  // 2. Icon Ba chấm (Menu mở rộng)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                    onSelected: (value) {
                      // Xử lý khi người dùng chọn các mục trong menu
                      if (value == 'copy_link') {
                        // Logic copy link video
                      } else if (value == 'report') {
                        // Logic báo cáo video
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy_link',
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.black),
                            SizedBox(width: 8),
                            Text("Sao chép liên kết"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.report_problem_outlined, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Báo cáo video", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}