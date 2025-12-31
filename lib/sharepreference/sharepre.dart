import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:instagram/provider/feed_provider.dart';

class LocalKeys {
  static const userId = 'userId';
  static const token = 'token'; // Firebase ID token (Bearer)
}

/// SAVE
Future<void> saveUserId(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(LocalKeys.userId, userId);
}

Future<void> saveIdToken(String idToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(LocalKeys.token, idToken);
}

/// GET
Future<String?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString(LocalKeys.userId);
  return (userId == null || userId.isEmpty) ? null : userId;
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(LocalKeys.token);
  return (token == null || token.isEmpty) ? null : token;
}

/// CLEAR (logout)
Future<void> logout(BuildContext context) async {
  // 1) clear local cache
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(LocalKeys.userId);
  await prefs.remove(LocalKeys.token);

  // 2) sign out firebase (để khỏi auto-login)
  await FirebaseAuth.instance.signOut(); // signOut là async [web:482]

  // 3) clear providers (tuỳ app bạn)
  if (context.mounted) {
    context.read<FeedProvider>().clearFeed();
  }

  // 4) go login
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }
}
