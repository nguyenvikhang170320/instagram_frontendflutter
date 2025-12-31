import 'package:flutter/foundation.dart';
import '../services/video_service.dart';

class WatchProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  // full objects from backend
  List<Map<String, dynamic>> videos = [];

  List<String> get videoUrls => videos
      .map((v) => (v['videoUrl'] ?? '').toString())
      .where((u) => u.isNotEmpty)
      .toList();

  Future<void> fetchAllVideos() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      videos = await VideoService.fetchAllVideos();
    } catch (e) {
      error = e.toString();
      videos = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserVideos(String userId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      videos = await VideoService.fetchUserVideos(userId);
    } catch (e) {
      error = e.toString();
      videos = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadVideo({
    required String filePath,
    String caption = "",
  }) async {
    error = null;
    try {
      final res =
          await VideoService.uploadVideo(filePath: filePath, caption: caption);
      return res['success'] == true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVideo(String videoId) async {
    error = null;

    // optimistic remove
    final prev = List<Map<String, dynamic>>.from(videos);
    videos = prev.where((v) => (v['id'] ?? '').toString() != videoId).toList();
    notifyListeners();

    try {
      await VideoService.deleteVideo(videoId);
      return true;
    } catch (e) {
      videos = prev; // rollback
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    loading = false;
    error = null;
    videos = [];
    notifyListeners();
  }
}
