import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:instagram/pages/watch/chewie_video_player.dart';
import 'package:instagram/pages/watch/video_item.dart';
import 'package:instagram/sharepreference/auth_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WatchScreen extends StatefulWidget {
  @override
  _WatchScreenState createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  List<Map<String, dynamic>> videos = [];
  List<VideoPlayerController> controllers = [];
  bool isLoading = true;
  int playingIndex = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void deactivate() {
    // Tự động dừng video đang phát khi rời khỏi màn hình Watch
    if (playingIndex < controllers.length) {
      controllers[playingIndex].pause();
    }
    super.deactivate();
  }

  Future<void> _fetchVideos() async {
    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['BASE_URL']}/video/videos'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['videos'] is List) {
          final fetchedVideos = List<Map<String, dynamic>>.from(data['videos']);

          videos = fetchedVideos.map((video) {
            return {
              "id": video["id"] ?? "",
              "caption": video["caption"] ?? "",
              "videoUrl": video["videoUrl"] ?? "",
              "userId": video["userId"] ?? "",
              "createdAt": video["createdAt"] ?? "",
            };
          }).toList();

          await _initializeControllers();
        } else {
          print("❌ Dữ liệu trả về không hợp lệ: $data");
        }
      } else {
        print("❌ API lỗi: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối API: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeControllers() async {
    for (var video in videos) {
      String url = video['videoUrl'];
      if (url.isNotEmpty) {
        final controller = VideoPlayerController.network(url);
        await controller.initialize();
        controllers.add(controller);
      }
    }

    if (controllers.isNotEmpty) {
      controllers[0].play();
    }

    if (mounted) setState(() {});
  }

  void _onPageChanged(int index) {
    if (index >= controllers.length) return;

    setState(() {
      controllers[playingIndex].pause(); // Dừng video cũ
      playingIndex = index;
      controllers[playingIndex].play(); // Phát video mới
    });
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      final videoFile = File(video.path);
      if (await videoFile.exists()) {
        print("📤 Chuẩn bị upload video: ${videoFile.path}");
        await _uploadVideo(videoFile);
      }
    }
  }

  Future<void> _uploadVideo(File videoFile) async {
    final userId = await getUserId();
    if (userId == null) {
      print("❌ Không tìm thấy userId");
      return;
    }

    final caption = await _showCaptionDialog(context);
    if (caption == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${dotenv.env['BASE_URL']}/video/upload'),
    );

    request.files
        .add(await http.MultipartFile.fromPath('video', videoFile.path));
    request.fields['caption'] = caption;
    request.fields['userId'] = userId;

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        print("✅ Upload thành công: ${jsonResponse['videoId']}");
        _reloadVideos();
      } else {
        print("❌ Upload thất bại: $jsonResponse");
      }
    } catch (e) {
      print("❌ Lỗi khi upload video: $e");
    }
  }

  Future<void> _reloadVideos() async {
    for (var controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    videos.clear();
    setState(() => isLoading = true);
    await _fetchVideos();
  }

  Future<String?> _showCaptionDialog(BuildContext context) async {
    final _controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Nhập mô tả video"),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: "Nhập caption..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final controllerReady = index < controllers.length &&
                        controllers[index].value.isInitialized;

                    return controllerReady
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    backgroundColor: Colors.black,
                                    body: Center(
                                      child: ChewieVideoPlayer(
                                          videoUrl: videos[index]['videoUrl']),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: VideoItem(
                              controller: controllers[index],
                              caption: videos[index]['caption'],
                              index: index,
                              playingIndex: playingIndex,
                              onTapPlay: (idx) => _onPageChanged(idx),
                            ),
                          )
                        : Center(child: CircularProgressIndicator());
                  },
                ),
                Positioned(
                  bottom: 50,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _pickVideo,
                    backgroundColor: Colors.pinkAccent,
                    child: Icon(Icons.add, size: 30, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }
}
