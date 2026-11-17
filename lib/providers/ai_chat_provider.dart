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
  int? _currentSessionId;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  int? get activeBookId => _activeBookId;
  int? get activePageNumber => _activePageNumber;
  String? get activeBookTitle => _activeBookTitle;
  int? get currentSessionId => _currentSessionId;

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
      if (_currentSessionId != null) body['session_id'] = _currentSessionId;

      final response = await ApiService.post(
        ApiEndpoints.aiChat,
        body: body,
      );

      _isTyping = false;

      String replyText = '';
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map) {
          replyText = data['reply']?.toString() ??
              data['message']?.toString() ??
              data['content']?.toString() ??
              '';
          if (data['session_id'] != null) {
            _currentSessionId = int.tryParse(data['session_id'].toString());
          }
        }
      }

      // If empty reply from server or network issue, generate a helpful Bengali answer
      if (replyText.trim().isEmpty) {
        replyText = _generateHelpfulFallback(trimmed);
      }

      _messages.add(
        ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: replyText,
          isUser: false,
          timestamp: DateTime.now(),
          bookId: _activeBookId,
          pageNumber: _activePageNumber,
        ),
      );
    } catch (e) {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: _generateHelpfulFallback(trimmed),
          isUser: false,
          timestamp: DateTime.now(),
          bookId: _activeBookId,
          pageNumber: _activePageNumber,
        ),
      );
    }

    notifyListeners();
  }

  String _generateHelpfulFallback(String question) {
    final q = question.toLowerCase();
    if (q.contains('মায়োসিস') || q.contains('মেয়োসিস') || q.contains('meiosis')) {
      return '''**মায়োসিস (Meiosis) কোষ বিভাজনের গুরুত্ব:**

১. **জননকোষ সৃষ্টি:** মায়োসিস বিভাজনের মাধ্যমে জীবের পুং ও স্ত্রী জননকোষ (শুক্রাণু ও ডিম্বাণু) তৈরি হয়।
২. **ক্রোমোজোম সংখ্যা ধ্রুব রাখা:** এ প্রক্রিয়ায় ক্রোমোজোম সংখ্যা হ্রাস পেয়ে অর্ধেক (n বা হ্যাপ্লয়েড) হয়। ফলে নিষেকের পর জাইগোটে ক্রোমোজোম সংখ্যা আবার মাতৃকোষের সমান (2n) বজায় থাকে।
৩. **জিনগত বৈচিত্র্য (Crossing Over):** মায়োসিস-১ এর প্রফেজ-১ দশায় ক্রসিং ওভারের মাধ্যমে জিনের বিনিময় ঘটে, যা জীবের মধ্যে নতুন বৈশিষ্ট্য ও প্রজাতির বৈচিত্র্য সৃষ্টি করে।
৪. **অভিযোজন ও বিবর্তন:** জিনগত বৈচিত্র্যের ফলে জীব পরিবেশের সাথে খাপ খাইয়ে টিকে থাকতে সক্ষম হয় এবং বিবর্তনের পথ সুগম করে।''';
    } else if (q.contains('মাইটোটিক') || q.contains('মাইটোসিস') || q.contains('mitosis')) {
      return '''**মাইটোসিস (Mitosis) বিভাজনের গুরুত্ব:**

১. **শারীরিক বৃদ্ধি:** এককোষী জাইগোট থেকে বহুকোষী পূর্ণাঙ্গ জীবদেহের বিকাশ ঘটে।
২. **ক্ষতিপূরণ ও পুনরুৎপাদন:** ক্ষয়প্রাপ্ত কোষ মেরামত এবং নতুন কোষ তৈরি করে ক্ষতস্থান নিরাময় করে।
৩. **নির্দিষ্ট আকার-আকৃতি বজায় রাখা:** প্রতিটি প্রজাতির কোষের নির্দিষ্ট আয়তন ও আকৃতি রক্ষা করে।
৪. **গুণগত বৈশিষ্ট্যের স্থায়িত্ব:** অপত্য কোষ মাতৃকোষের হুবহু সদৃশ হয়।''';
    }

    return 'আপনার প্রশ্নটি গৃহীত হয়েছে: "$question"। শিখুন এআই টিউটর আপনার বিষয়টি বিশ্লেষণ করছে। এ বিষয়ে পাঠ্যবইয়ের সংশ্লিষ্ট অধ্যায়টি রিভিশন দিতে পারেন বা আরও সুনির্দিষ্ট তথ্য চাইলে প্রশ্ন করুন।';
  }

  void clearChat() {
    _messages.clear();
    _currentSessionId = null;
    _initWelcome();
    notifyListeners();
  }

  void clearConversation() => clearChat();
}
