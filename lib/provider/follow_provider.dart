import 'package:flutter/foundation.dart';
import '../services/follow_service.dart';

class FollowProvider extends ChangeNotifier {
  final FollowService _service = FollowService();

  bool isLoading = false;
  String? error;

  int followersCount = 0;
  int followingCount = 0;

  // quick check
  final Set<String> followingIds = {};

  // lists for FollowScreen
  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];

  Future<void> loadCounts(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _service.getFollowCounts(userId);
      followersCount = (data["followersCount"] ?? 0) as int;
      followingCount = (data["followingCount"] ?? 0) as int;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFollowingIds(String userId) async {
    try {
      final ids = await _service.getFollowingIds(userId);
      followingIds
        ..clear()
        ..addAll(ids);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  bool isFollowing(String targetUserId) => followingIds.contains(targetUserId);

  Future<void> loadFollowersList(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      followers = await _service.getFollowersUsers(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFollowingList(String userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      following = await _service.getFollowingUsers(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> follow(String targetUserId, {String? myUserIdForRefresh}) async {
    // optimistic
    followingIds.add(targetUserId);
    followingCount += 1;
    notifyListeners();

    try {
      await _service.followUser(followingId: targetUserId);
      if (myUserIdForRefresh != null) {
        await loadCounts(myUserIdForRefresh);
      }
      return true;
    } catch (e) {
      // rollback
      followingIds.remove(targetUserId);
      followingCount = (followingCount - 1).clamp(0, 1 << 31);
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unfollow(String targetUserId, {String? myUserIdForRefresh}) async {
    // optimistic
    followingIds.remove(targetUserId);
    followingCount = (followingCount - 1).clamp(0, 1 << 31);
    notifyListeners();

    try {
      await _service.unfollowUser(followingId: targetUserId);
      if (myUserIdForRefresh != null) {
        await loadCounts(myUserIdForRefresh);
      }
      return true;
    } catch (e) {
      // rollback
      followingIds.add(targetUserId);
      followingCount += 1;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    isLoading = false;
    error = null;
    followersCount = 0;
    followingCount = 0;
    followingIds.clear();
    followers = [];
    following = [];
    notifyListeners();
  }
}
