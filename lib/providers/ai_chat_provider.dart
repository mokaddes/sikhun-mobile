import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/ai_chat_model.dart';
import '../services/api_service.dart';

class AiChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int? _activeBookId;
  int? _activePageNumber;
  String? _activeBookTitle;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  int? get activeBookId => _activeBookId;
  int? get activePageNumber => _activePageNumber;
  String? get activeBookTitle => _activeBookTitle;

  AiChatProvider() {
    _initWelcome();
  }

  void _initWelcome() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          id: 'welcome_1',
          content: 'স্বাগতম! আমি শিখুন AI টিউটর। যেকোনো অধ্যায়, কঠিন টপিক বা বইয়ের নির্দিষ্ট পাতা সম্পর্কে আমাকে প্রশ্ন করতে পারেন।',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void setContext({int? bookId, int? pageNumber, String? bookTitle}) {
    _activeBookId = bookId;
    _activePageNumber = pageNumber;
    _activeBookTitle = bookTitle;
    notifyListeners();
  }

  void clearContext() {
    _activeBookId = null;
    _activePageNumber = null;
    _activeBookTitle = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      bookId: _activeBookId,
      pageNumber: _activePageNumber,
      bookTitle: _activeBookTitle,
    );

    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'message': trimmed,
      };
      if (_activeBookId != null) body['book_id'] = _activeBookId;
      if (_activePageNumber != null) body['page_number'] = _activePageNumber;

      final response = await ApiService.post(
        ApiEndpoints.aiSessions,
        body: body,
      );

      _isTyping = false;

      if (response.success && response.data != null) {
        final replyText = response.data['reply'] ??
            response.data['message'] ??
            response.data['response'] ??
            'দুঃখিত, কোনো উত্তর পাওয়া যায়নি।';

        _messages.add(
          ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            content: replyText.toString(),
            isUser: false,
            timestamp: DateTime.now(),
            bookId: _activeBookId,
            pageNumber: _activePageNumber,
          ),
        );
      } else {
        _messages.add(
          ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            content: response.message ?? 'দুঃখিত, এই মুহূর্তে এআই সার্ভিসের সাথে যোগাযোগ করা সম্ভব হচ্ছে না।',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      }
    } catch (e) {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: 'কানেকশন ত্রুটি: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    }

    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    _initWelcome();
    notifyListeners();
  }
}
