import 'package:flutter/foundation.dart';
import '../services/save_service.dart';

class SaveProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  final Set<String> savedPostIds = {};                // postId
  final Map<String, String> imageUrlByPostId = {};    // postId -> imageUrl

  int get savedCount => savedPostIds.length;

  bool isSaved(String postId) => savedPostIds.contains(postId);
  String imageUrlOf(String postId) => imageUrlByPostId[postId] ?? '';

  Future<void> fetchSavedPosts({bool force = false}) async {
    if (loading) return;
    if (!force && savedPostIds.isNotEmpty) return;

    loading = true;
    error = null;
    notifyListeners();

    try {
      final items = await SavedService.getSavedPosts(); // List<Map>
      savedPostIds.clear();
      imageUrlByPostId.clear();

      for (final e in items) {
        final postId = (e['postId'] ?? '').toString();
        final imageUrl = (e['imageUrl'] ?? '').toString();
        if (postId.isEmpty) continue;
        savedPostIds.add(postId);
        if (imageUrl.isNotEmpty) imageUrlByPostId[postId] = imageUrl;
      }
    } catch (e) {
      error = e.toString();
      savedPostIds.clear();
      imageUrlByPostId.clear();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSave({
    required String postId,
    required String imageUrl,
    required bool nextValue,
  }) async {
    error = null;
    final had = isSaved(postId);

    // optimistic
    if (nextValue) {
      savedPostIds.add(postId);
      imageUrlByPostId[postId] = imageUrl;
    } else {
      savedPostIds.remove(postId);
      imageUrlByPostId.remove(postId);
    }
    notifyListeners();

    try {
      if (nextValue) {
        await SavedService.savePost(postId: postId, imageUrl: imageUrl);
      } else {
        await SavedService.unsavePost(postId: postId);
      }
      return true;
    } catch (e) {
      // rollback
      if (had) {
        savedPostIds.add(postId);
        imageUrlByPostId[postId] = imageUrl;
      } else {
        savedPostIds.remove(postId);
        imageUrlByPostId.remove(postId);
      }
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    loading = false;
    error = null;
    savedPostIds.clear();
    imageUrlByPostId.clear();
    notifyListeners();
  }
}
