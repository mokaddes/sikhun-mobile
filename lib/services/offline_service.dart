import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';

class OfflineService extends ChangeNotifier {
  static const String _cachedBooksKey = 'sikhun_offline_books';
  static const String _cachedChaptersPrefix = 'sikhun_offline_ch_';

  List<BookModel> _offlineBooks = [];
  bool _isOfflineMode = false;

  List<BookModel> get offlineBooks => _offlineBooks;
  bool get isOfflineMode => _isOfflineMode;

  OfflineService() {
    loadCachedBooks();
  }

  void setOfflineMode(bool value) {
    _isOfflineMode = value;
    notifyListeners();
  }

  Future<void> loadCachedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cachedBooksKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List list = jsonDecode(jsonString);
        _offlineBooks = list.map((item) => BookModel.fromJson(item)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading offline books: $e');
      }
    }
  }

  Future<bool> saveBookForOffline(BookModel book, {Map<String, dynamic>? chapterContent}) async {
    final prefs = await SharedPreferences.getInstance();
    final existingIndex = _offlineBooks.indexWhere((b) => b.id == book.id);
    if (existingIndex >= 0) {
      _offlineBooks[existingIndex] = book;
    } else {
      _offlineBooks.add(book);
    }

    final encoded = jsonEncode(_offlineBooks.map((b) => {
      'id': b.id,
      'title': b.title,
      'slug': b.slug,
      'author': b.author,
      'cover_image': b.coverImage,
      'total_pages': b.totalPages,
      'progress': b.progress,
      'last_read_page': b.lastReadPage,
      'is_free': b.isFree,
      'chapters': b.chapters.map((c) => {
        'id': c.id,
        'book_id': c.bookId,
        'title': c.title,
        'start_page': c.pageStart,
        'end_page': c.pageEnd,
      }).toList(),
    }).toList());

    await prefs.setString(_cachedBooksKey, encoded);

    if (chapterContent != null) {
      await prefs.setString('$_cachedChaptersPrefix${book.id}', jsonEncode(chapterContent));
    }

    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>?> getOfflineChapterContent(int bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString('$_cachedChaptersPrefix$bookId');
    if (content != null && content.isNotEmpty) {
      try {
        return jsonDecode(content);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool isBookDownloaded(int bookId) {
    return _offlineBooks.any((b) => b.id == bookId);
  }

  Future<void> removeOfflineBook(int bookId) async {
    _offlineBooks.removeWhere((b) => b.id == bookId);
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_offlineBooks.map((b) => {
      'id': b.id,
      'title': b.title,
      'slug': b.slug,
      'author': b.author,
      'cover_image': b.coverImage,
      'total_pages': b.totalPages,
      'progress': b.progress,
      'last_read_page': b.lastReadPage,
      'is_free': b.isFree,
    }).toList());
    await prefs.setString(_cachedBooksKey, encoded);
    await prefs.remove('$_cachedChaptersPrefix$bookId');
    notifyListeners();
  }
}
