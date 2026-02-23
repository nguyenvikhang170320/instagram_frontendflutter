import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/chat_model.dart';
import '../model/message_model.dart';
import '../services/chat_service.dart';
import '../services/message_service.dart';

class ChatProvider with ChangeNotifier {
  // ===============================
  // STATE
  // ===============================

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];

  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  // ===============================
  // GETTERS
  // ===============================

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;

  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  final ChatService _chatService = ChatService();
  // ===============================
  // LOAD CHAT LIST
  // ===============================

  Future<void> loadChats() async {
    _isLoadingChats = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;

      _chats = await _chatService.getChats(token);

    } catch (e) {
      debugPrint('Load chats error: $e');
    } finally {
      _isLoadingChats = false;
      notifyListeners();
    }
  }

  // ===============================
  // LOAD MESSAGES
  // ===============================

  Future<void> loadMessages(String chatId) async {
    _isLoadingMessages = true;
    _messages = [];
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;

      _messages = await MessageService.fetchMessages(
        token: token,
        chatId: chatId,
      );
    } catch (e) {
      debugPrint('Load messages error: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // ===============================
  // SEND TEXT MESSAGE
  // ===============================

  Future<void> sendTextMessage({
    required String chatId,
    required String text,
    required String currentUserId,
  }) async {
    if (text.trim().isEmpty) return;

    final tempMessage = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: currentUserId,
      text: text,
      type: 'text',
      createdAt: DateTime.now(),
    );

    // ✅ 1. Update UI NGAY LẬP TỨC
    _messages.add(tempMessage);
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;

      await MessageService.sendText(
        token: token,
        chatId: chatId,
        text: text,
      );

      // ✅ 2. Update chat list (lastMessage)
      await loadChats();

    } catch (e) {
      // ❌ rollback nếu gửi lỗi
      _messages.remove(tempMessage);
      notifyListeners();
      debugPrint('Send text error: $e');
    }
  }


  // ===============================
  // SEND MEDIA MESSAGE
  // ===============================

  Future<void> sendMediaMessage({
    required String chatId,
    required File filePath,
    required String currentUserId,
  }) async {
    final tempMessage = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: currentUserId,
      text: '',
      type: 'image',
      createdAt: DateTime.now(),
      mediaUrl: filePath.path,
      localImagePath: filePath.path,// nếu có
    );

    _messages.add(tempMessage);
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;

      await MessageService.sendMedia(
        token: token,
        chatId: chatId,
        imageFile: filePath,
      );

      await loadChats();

    } catch (e) {
      _messages.remove(tempMessage);
      notifyListeners();
      debugPrint('Send media error: $e');
    }
  }


  // ===============================
  // GET FIREBASE TOKEN
  // ===============================

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(true);
  }
}
