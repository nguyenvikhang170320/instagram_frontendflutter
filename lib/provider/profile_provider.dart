import 'dart:io';
import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  bool loading = false;
  String? error;

  User profile = User.empty();

  Future<void> fetchProfile(String userId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _profileService.fetchProfile(userId); // Map<String,dynamic>
      profile = User.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      error = e.toString();
      profile = User.empty();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String userId,
    required String username,
    required String fullname,
    required String bio,
    File? avatarFile,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _profileService.updateProfile(
        userId: userId,
        username: username,
        fullname: fullname,
        bio: bio,
        avatarFile: avatarFile,
      );

      // nếu backend trả full user thì parse
      if (data is Map && data.containsKey('user')) {
        profile = User.fromJson(Map<String, dynamic>.from(data['user']));
      } else {
        // update local chỉ những cái có gửi lên
        profile = profile.copyWith(
          username: username ?? profile.username,
          fullname: fullname ?? profile.fullname,
          bio: bio ?? profile.bio,
          avatar: (data['avatar'] ?? profile.avatar).toString(),
        );
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

}
