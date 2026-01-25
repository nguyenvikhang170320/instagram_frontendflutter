import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/story_model.dart';
import '../services/story_service.dart';

class StoryProvider with ChangeNotifier {
  final StoryService _service = StoryService();

  List<StoryGroup> _storyGroups = [];
  bool _isLoading = false;

  List<StoryGroup> get storyGroups => _storyGroups;
  bool get isLoading => _isLoading;

  Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  // Load danh sách
  Future<void> loadStories() async {
    _isLoading = true;
    notifyListeners();
    try {
      String? token = await _getToken();
      if (token != null) {
        _storyGroups = await _service.fetchStories(token);
      }
    } catch (e) {
      print("Lỗi load stories: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload
  Future<bool> postStory(File imageFile) async {
    try {
      String? token = await _getToken();
      if (token == null) return false;
      bool success = await _service.uploadStory(token, imageFile);
      if (success) await loadStories(); // Refresh lại list
      return success;
    } catch (e) {
      print("Lỗi post story: $e");
      return false;
    }
  }

  // Đánh dấu đã xem (Local update cho mượt)
  Future<void> markAsViewed(String storyId, String userId) async {
    try {
      for (var group in _storyGroups) {
        if (group.userId == userId) {
          for (var story in group.stories) {
            if (story.storyId == storyId && !story.isViewed) {
              story.isViewed = true;
              notifyListeners();

              String? token = await _getToken();
              if (token != null) await _service.viewStory(token, storyId);
              return;
            }
          }
        }
      }
    } catch (e) {
      print("Lỗi view story: $e");
    }
  }

  // Lấy danh sách người xem
  Future<List<Map<String, dynamic>>> getViewers(String storyId) async {
    try {
      String? token = await _getToken();
      if (token == null) return [];
      return await _service.fetchViewers(token, storyId);
    } catch (e) {
      print("Lỗi get viewers: $e");
      return [];
    }
  }

  // Xóa Story & Cập nhật UI ngay lập tức
  Future<bool> deleteStory(String storyId) async {
    try {
      String? token = await _getToken();
      if (token == null) return false;

      bool success = await _service.deleteStory(token, storyId);

      if (success) {
        // Logic xóa cục bộ (Local Removal)
        for (var group in _storyGroups) {
          // Tìm và xóa story trong group
          group.stories.removeWhere((s) => s.storyId == storyId);
        }
        // Nếu group không còn story nào -> Xóa luôn group đó khỏi feed
        _storyGroups.removeWhere((group) => group.stories.isEmpty);

        notifyListeners(); // Báo UI vẽ lại
      }
      return success;
    } catch (e) {
      print("Lỗi xóa story: $e");
      return false;
    }
  }
}