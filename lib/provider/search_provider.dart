import 'package:flutter/foundation.dart';
import '../services/search_service.dart';

class SearchProvider extends ChangeNotifier {
  final SearchService _service = SearchService();

  bool loading = false;
  String? error;

  String _query = "";
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];

  List<Map<String, dynamic>> get users => _filtered;
  String get query => _query;

  Future<void> load(String currentUserId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      _users = await _service.fetchUsersForSearch(currentUserId: currentUserId);
      _applyFilter(_query);
    } catch (e) {
      error = e.toString();
      _users = [];
      _filtered = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _query = query.trim();
    _applyFilter(_query);
    notifyListeners();
  }

  void _applyFilter(String q) {
    if (q.isEmpty) {
      _filtered = List<Map<String, dynamic>>.from(_users);
      return;
    }

    final lower = q.toLowerCase();
    _filtered = _users.where((u) {
      final username = (u["username"] ?? "").toString().toLowerCase();
      final fullname = (u["fullname"] ?? "").toString().toLowerCase();
      return username.contains(lower) || fullname.contains(lower);
    }).toList();
  }

  /// Nếu bạn muốn UI update ngay khi follow/unfollow ở SearchScreen
  void setFollowing(String targetUserId, bool isFollowing) {
    for (final u in _users) {
      if (u["userId"] == targetUserId) {
        u["isFollowing"] = isFollowing;
        break;
      }
    }
    _applyFilter(_query);
    notifyListeners();
  }

  void clear() {
    loading = false;
    error = null;
    _query = "";
    _users = [];
    _filtered = [];
    notifyListeners();
  }
}
