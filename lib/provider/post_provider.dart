import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _service = PostService();

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> posts = [];

  Future<void> fetchUserPosts(String userId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      posts = await _service.fetchUserPosts(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPost({
    required String userId,
    required File imageFile,
    required String caption,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _service.uploadPost(imageFile: imageFile, caption: caption);

      // Sau upload, reload list cho chắc (vì backend tạo createdAt serverTimestamp)
      posts = await _service.fetchUserPosts(userId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost({
    required String userId,
    required String postId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    // optimistic remove
    final backup = List<Map<String, dynamic>>.from(posts);
    posts.removeWhere((p) => p["postId"] == postId || p["id"] == postId);
    notifyListeners();

    try {
      await _service.deletePost(postId);
      // reload để chắc chắn đồng bộ
      posts = await _service.fetchUserPosts(userId);
      return true;
    } catch (e) {
      posts = backup; // rollback
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    posts = [];
    loading = false;
    error = null;
    notifyListeners();
  }
}
