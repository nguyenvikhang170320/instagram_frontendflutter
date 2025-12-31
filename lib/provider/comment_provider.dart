import 'package:flutter/foundation.dart';
import '../services/comment_service.dart';

class CommentProvider extends ChangeNotifier {
  bool loadingCount = false;
  bool loadingList = false;
  String? error;

  final Map<String, int> commentCountMap = {}; // postId -> count
  final Map<String, List<Map<String, dynamic>>> commentsMap = {}; // postId -> list

  int commentCountOf(String postId) => commentCountMap[postId] ?? 0;
  List<Map<String, dynamic>> commentsOf(String postId) => commentsMap[postId] ?? [];

  Future<void> fetchCommentCount(String postId) async {
    loadingCount = true;
    error = null;
    notifyListeners();

    try {
      final count = await CommentService.fetchCommentCount(postId);
      commentCountMap[postId] = count;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingCount = false;
      notifyListeners();
    }
  }

  Future<void> fetchComments(String postId) async {
    loadingList = true;
    error = null;
    notifyListeners();

    try {
      final list = await CommentService.fetchComments(postId);
      commentsMap[postId] = list;
      // đồng bộ count luôn (đỡ gọi count api nếu muốn)
      commentCountMap[postId] = list.length;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required String postId,
    required String commentText,
  }) async {
    error = null;

    try {
      final newComment = await CommentService.addComment(
        postId: postId,
        commentText: commentText,
      );

      final current = commentsMap[postId] ?? [];
      commentsMap[postId] = [newComment, ...current];
      commentCountMap[postId] = (commentCountMap[postId] ?? current.length) + 1;

      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    error = null;

    // optimistic remove
    final prevList = List<Map<String, dynamic>>.from(commentsMap[postId] ?? []);
    final prevCount = commentCountOf(postId);

    commentsMap[postId] = prevList.where((e) => e['commentId'] != commentId).toList();
    commentCountMap[postId] = (prevCount - 1) < 0 ? 0 : (prevCount - 1);
    notifyListeners();

    try {
      await CommentService.deleteComment(commentId: commentId);
      return true;
    } catch (e) {
      // rollback
      commentsMap[postId] = prevList;
      commentCountMap[postId] = prevCount;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    error = null;
    loadingCount = false;
    loadingList = false;
    commentCountMap.clear();
    commentsMap.clear();
    notifyListeners();
  }
}
