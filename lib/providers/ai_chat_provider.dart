import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/ai_chat_model.dart';
import '../services/api_service.dart';

class AiChatSessionSummary {
  final int id;
  final String title;
  final String sourceType;
  final int? sourceBookId;
  final int? sourceMyBookId;
  final String? createdAt;

  AiChatSessionSummary({
    required this.id,
    required this.title,
    this.sourceType = 'none',
    this.sourceBookId,
    this.sourceMyBookId,
    this.createdAt,
  });

  factory AiChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return AiChatSessionSummary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: (json['title'] ?? 'নতুন চ্যাট').toString(),
      sourceType: (json['source_type'] ?? 'none').toString(),
      sourceBookId: json['source_book_id'] is int ? json['source_book_id'] : int.tryParse(json['source_book_id']?.toString() ?? ''),
      sourceMyBookId: json['source_my_book_id'] is int ? json['source_my_book_id'] : int.tryParse(json['source_my_book_id']?.toString() ?? ''),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class AiChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<AiChatSessionSummary> _sessions = [];
  bool _isTyping = false;
  bool _isLoadingSessions = false;
  int? _activeBookId;
  int? _activeMyBookId;
  int? _activePageNumber;
  String? _activeBookTitle;
  int? _currentSessionId;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  List<AiChatSessionSummary> get sessions => _sessions;
  bool get isTyping => _isTyping;
  bool get isLoadingSessions => _isLoadingSessions;
  int? get activeBookId => _activeBookId;
  int? get activeMyBookId => _activeMyBookId;
  int? get activePageNumber => _activePageNumber;
  String? get activeBookTitle => _activeBookTitle;
  int? get currentSessionId => _currentSessionId;
  String? get errorMessage => _errorMessage;

  AiChatProvider() {
    _initWelcome();
  }

  void _initWelcome() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          id: 'welcome_1',
          content: 'স্বাগতম! আমি শিখুন AI টিউটর। যেকোনো অধ্যায়, কঠিন টপিক বা আপনার বইয়ের নির্দিষ্ট পাতা সম্পর্কে আমাকে প্রশ্ন করতে পারেন।',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void setContext({int? bookId, int? myBookId, int? pageNumber, String? bookTitle}) {
    _activeBookId = bookId;
    _activeMyBookId = myBookId;
    _activePageNumber = pageNumber;
    _activeBookTitle = bookTitle;
    notifyListeners();
  }

  void clearContext() {
    _activeBookId = null;
    _activeMyBookId = null;
    _activePageNumber = null;
    _activeBookTitle = null;
    notifyListeners();
  }

  Future<void> fetchSessions() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return;

    _isLoadingSessions = true;
    notifyListeners();

    final res = await ApiService.get(ApiEndpoints.aiSessions);
    _isLoadingSessions = false;

    if (res.success && res.data is List) {
      _sessions = (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(AiChatSessionSummary.fromJson)
          .toList();
    }
    notifyListeners();
  }

  Future<void> loadSession(int sessionId) async {
    final res = await ApiService.get(ApiEndpoints.aiSession(sessionId));
    if (res.success && res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      _currentSessionId = sessionId;
      _activeBookId = data['source_book_id'] is int ? data['source_book_id'] : int.tryParse(data['source_book_id']?.toString() ?? '');
      _activeMyBookId = data['source_my_book_id'] is int ? data['source_my_book_id'] : int.tryParse(data['source_my_book_id']?.toString() ?? '');
      _messages.clear();
      if (data['messages'] is List) {
        int i = 0;
        for (final m in data['messages'] as List) {
          if (m is Map) {
            _messages.add(ChatMessage(
              id: 's_${sessionId}_${i++}',
              content: (m['content'] ?? '').toString(),
              isUser: (m['role'] ?? '') == 'user',
              timestamp: DateTime.now(),
            ));
          }
        }
      }
      if (_messages.isEmpty) _initWelcome();
      notifyListeners();
    }
  }

  Future<void> renameSession(int sessionId, String title) async {
    final res = await ApiService.patch(ApiEndpoints.aiSession(sessionId), body: {'title': title});
    if (res.success) {
      await fetchSessions();
    }
  }

  Future<void> deleteSession(int sessionId) async {
    final res = await ApiService.delete(ApiEndpoints.aiSession(sessionId));
    if (res.success) {
      if (_currentSessionId == sessionId) {
        clearChat();
      }
      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
    }
  }

  Future<void> attachBookToCurrentSession({int? bookId, int? myBookId, String? title}) async {
    setContext(bookId: bookId, myBookId: myBookId, bookTitle: title);
    if (_currentSessionId != null) {
      await ApiService.patch(
        ApiEndpoints.aiSessionBook(_currentSessionId!),
        body: {
          'source_book_id': bookId,
          'source_my_book_id': myBookId,
        },
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _errorMessage = null;
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_auth',
        content: 'শিখুন AI টিউটর ব্যবহার করতে অনুগ্রহ করে আপনার অ্যাকাউন্টে লগইন করুন।',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
      return;
    }

    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      bookId: _activeBookId,
      pageNumber: _activePageNumber,
      bookTitle: _activeBookTitle,
    ));

    final botId = '${DateTime.now().millisecondsSinceEpoch}_bot';
    _messages.add(ChatMessage(
      id: botId,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      bookId: _activeBookId,
      pageNumber: _activePageNumber,
    ));

    _isTyping = true;
    notifyListeners();

    try {
      // Create a session if none is active
      if (_currentSessionId == null) {
        final createRes = await ApiService.post(
          ApiEndpoints.aiSessions,
          body: {
            if (_activeBookId != null) 'source_book_id': _activeBookId,
            if (_activeMyBookId != null) 'source_my_book_id': _activeMyBookId,
            'title': trimmed.length > 48 ? '${trimmed.substring(0, 48)}...' : trimmed,
          },
        );
        if (createRes.success && createRes.data is Map && createRes.data['id'] != null) {
          _currentSessionId = int.tryParse(createRes.data['id'].toString());
          fetchSessions();
        } else {
          _isTyping = false;
          _updateBotMessage(botId, createRes.message ?? 'AI সেশন তৈরি করা যায়নি।');
          return;
        }
      }

      if (_currentSessionId != null) {
        final buffer = StringBuffer();
        await for (final event in ApiService.postSseStream(
          ApiEndpoints.aiSessionMessages(_currentSessionId!),
          body: {'message': trimmed},
        )) {
          if (event['error'] != null) {
            buffer.clear();
            buffer.write(event['error'].toString());
            break;
          }
          final delta = event['content']?.toString() ?? '';
          if (delta.isNotEmpty) {
            buffer.write(delta);
            _updateBotMessage(botId, buffer.toString());
          }
          if (event['done'] == true) {
            break;
          }
        }
        if (buffer.isEmpty) {
          _updateBotMessage(botId, 'উত্তর পাওয়া যায়নি। কিছুক্ষণ পর আবার চেষ্টা করুন।');
        }
      }
    } catch (e) {
      _updateBotMessage(botId, 'AI সংযোগে সাময়িক ত্রুটি হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void _updateBotMessage(String botId, String content) {
    final idx = _messages.indexWhere((m) => m.id == botId);
    if (idx != -1) {
      final old = _messages[idx];
      _messages[idx] = ChatMessage(
        id: old.id,
        content: content,
        isUser: false,
        timestamp: old.timestamp,
        bookId: old.bookId,
        pageNumber: old.pageNumber,
        bookTitle: old.bookTitle,
      );
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _currentSessionId = null;
    _initWelcome();
    notifyListeners();
  }

  void clearConversation() => clearChat();
}
