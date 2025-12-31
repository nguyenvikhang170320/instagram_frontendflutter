import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram/sharepreference/sharepre.dart';

class FeedProvider extends ChangeNotifier {
  String userId = "";
  List<Map<String, dynamic>> posts = [];
  bool isLoading = false;

  FeedProvider() {
    _initUserId();
  }

  Future<void> _initUserId() async {
    final uid = await getUserId();        // String?
    userId = uid ?? "";                   // convert to non-null
    if (userId.isNotEmpty) {
      await fetchFeed(userId);
    } else {
      posts = [];
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeed(String uid) async {
    final apiUrl = "${dotenv.env['BASE_URL']}/profile/feed/$uid";
    isLoading = true;
    notifyListeners();

    try {
      final res = await http.get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        posts = List<Map<String, dynamic>>.from(data["posts"] ?? []);
      } else {
        posts = [];
      }
    } catch (_) {
      posts = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    if (userId.isEmpty) {
      await _initUserId();
      return;
    }
    await fetchFeed(userId);
  }

  Future<void> updateUserId(String newUserId) async {
    userId = newUserId;
    await fetchFeed(userId);
  }

  void clearFeed() {
    userId = "";
    posts = [];
    isLoading = false;
    notifyListeners();
  }
}
