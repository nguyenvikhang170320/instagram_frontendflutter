import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/chat_model.dart';
import '../model/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _service = ChatService();

  // State cho Danh sách Chat (Màn hình Chat List)
  List<ChatModel> _chats = [];
  bool _isLoadingChats = false;

  // State cho Chi tiết Tin nhắn (Màn hình Chat Detail)
  List<MessageModel> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;

  // Getters
  List<ChatModel> get chats => _chats;
  bool get isLoadingChats => _isLoadingChats;

  List<MessageModel> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;

  // ==========================================
  // 1. LOAD DANH SÁCH CHAT
  // ==========================================
  Future<void> loadChats() async {
    _isLoadingChats = true;
    notifyListeners(); // Báo UI hiện loading

    try {
      String? token = await _getToken();
      if (token != null) {
        _chats = await _service.getChats(token);
      }
    } catch (e) {
      print("Lỗi Provider loadChats: $e");
    } finally {
      _isLoadingChats = false;
      notifyListeners(); // Báo UI update dữ liệu
    }
  }

  // ==========================================
  // 2. LOAD TIN NHẮN CỦA 1 PHÒNG
  // ==========================================
  Future<void> loadMessages(String chatId) async {
    _isLoadingMessages = true;
    // Lưu ý: Có thể clear message cũ để tránh hiện tin nhắn của người trước
    _messages = [];
    notifyListeners();

    try {
      String? token = await _getToken();
      if (token != null) {
        _messages = await _service.getMessages(token, chatId);
      }
    } catch (e) {
      print("Lỗi Provider loadMessages: $e");
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 3. GỬI TIN NHẮN
  // ==========================================
  Future<void> sendMessage(String chatId, String text, String currentUserId) async {
    if (text.trim().isEmpty) return;

    _isSending = true;
    notifyListeners();

    try {
      String? token = await _getToken();
      if (token != null) {
        bool success = await _service.sendMessage(token, chatId, text);

        if (success) {
          // A. Cách 1: Load lại toàn bộ tin nhắn từ server (An toàn nhất)
          // await loadMessages(chatId);

          // B. Cách 2: Tự thêm tin nhắn vào list local cho mượt (Optimistic UI)
          // Tạo một model giả lập để hiện ngay lập tức
          final newMessage = MessageModel(
            id: "temp_${DateTime.now().millisecondsSinceEpoch}",
            chatId: chatId,
            senderId: currentUserId,
            text: text,
            createdAt: DateTime.now(), // Lưu ý format ngày
          );

          _messages.add(newMessage);

          // Cũng cần update lại lastMessage trong danh sách _chats
          final chatIndex = _chats.indexWhere((c) => c.chatId == chatId);
          if (chatIndex != -1) {
            // Đưa chat này lên đầu danh sách
            final updatedChat = _chats[chatIndex];
            // Cần setter hoặc copyWith cho ChatModel để update lastMessage
            // _chats.removeAt(chatIndex);
            // _chats.insert(0, updatedChat);
          }
        }
      }
    } catch (e) {
      print("Lỗi Provider sendMessage: $e");
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // Helper: Lấy Token Firebase
  Future<String?> _getToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken(true); // Force refresh để tránh token hết hạn
    }
    return null;
  }
}