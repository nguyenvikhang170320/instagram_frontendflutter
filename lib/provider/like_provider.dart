import 'package:flutter/foundation.dart';
import '../services/like_service.dart';

class LikeProvider extends ChangeNotifier {
  final LikeService _service = LikeService();

  bool loadingLikedMap = false;
  bool loadingCount = false;
  String? error;

  /// postId -> true/false (đã like chưa)
  Map<String, bool> likedPostsMap = {};

  /// postId -> likeCount
  Map<String, int> likeCountMap = {};

  bool isLiked(String postId) => likedPostsMap[postId] == true;
  int likeCountOf(String postId) => likeCountMap[postId] ?? 0;

  /// GET /likes/user/:userId
  Future<void> fetchLikedPosts(String userId) async {
    loadingLikedMap = true;
    error = null;
    notifyListeners();

    try {
      likedPostsMap = await _service.fetchLikedPostsMap(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      loadingLikedMap = false;
      notifyListeners();
    }
  }

  /// GET /likes/:postId (likeCount)
  Future<void> fetchLikeCount(String postId) async {
    loadingCount = true;
    error = null;
    notifyListeners();

    try {
      final data = await _service.fetchLikeInfo(postId);
      likeCountMap[postId] = (data['likeCount'] ?? 0) as int;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingCount = false;
      notifyListeners();
    }
  }

  /// Toggle like/unlike (optimistic) + cập nhật count local
  Future<void> toggleLike({
    required String postId,
    required bool nextValue,
  }) async {
    final prevLiked = isLiked(postId);
    final prevCount = likeCountOf(postId);

    likedPostsMap[postId] = nextValue;
    likeCountMap[postId] = prevCount + (nextValue ? 1 : -1);
    if (likeCountMap[postId]! < 0) likeCountMap[postId] = 0;

    error = null;
    notifyListeners();

    try {
      if (nextValue) {
        await _service.like(postId);
      } else {
        await _service.unlike(postId);
      }
    } catch (e) {
      // rollback
      likedPostsMap[postId] = prevLiked;
      likeCountMap[postId] = prevCount;
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clear() {
    likedPostsMap = {};
    likeCountMap = {};
    loadingLikedMap = false;
    loadingCount = false;
    error = null;
    notifyListeners();
  }
}
