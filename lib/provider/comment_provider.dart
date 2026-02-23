import 'package:flutter/material.dart';
import '../services/comment_service.dart';

class CommentProvider extends ChangeNotifier {

  final Map<String, List<Map<String, dynamic>>> _commentsMap = {};

  List<Map<String, dynamic>> commentsOf(String postId) =>
      _commentsMap[postId] ?? [];


  Future<void> fetchComments(String postId) async {
    final list = await CommentService.fetchComments(postId);
    _commentsMap[postId] = list;
    notifyListeners();
  }


  Future<void> addComment({
    required String postId,
    required String userId,
    required String text
  }) async {

    await CommentService.addComment(
      postId: postId,
      userId: userId,
      commentText: text,
    );

    await fetchComments(postId); // reload
  }


  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {

    await CommentService.deleteComment(
      postId: postId,
      commentId: commentId,
    );

    await fetchComments(postId);
  }
}