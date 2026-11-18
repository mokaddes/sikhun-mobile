import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<BookModel> _books = [];
  List<BookModel> _bookshelf = [];
  List<Map<String, dynamic>> _myBooks = [];
  Map<String, dynamic> _uploadQuota = const {'current_count': 0, 'max_slots': 1, 'reuploads_remaining': 0};
  BookModel? _selectedBook;
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'all';

  List<BookModel> get books => _books;
  List<BookModel> get bookshelf => _bookshelf;
  List<Map<String, dynamic>> get myBooks => _myBooks;
  Map<String, dynamic> get uploadQuota => _uploadQuota;
  BookModel? get selectedBook => _selectedBook;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  void setCategory(String category) {
    _selectedCategory = category;
    fetchBooks(level: category == 'all' ? null : category.toLowerCase());
  }

  Future<void> fetchBooks({String? level, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (level != null && level.isNotEmpty && level != 'all') {
      query['level'] = level.toLowerCase();
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await ApiService.get(ApiEndpoints.library, queryParams: query);
    _isLoading = false;

    if (response.success && response.data != null) {
      final list = (response.data is List)
          ? response.data as List
          : (response.data['books'] ?? response.data['data'] ?? []) as List;
      _books = list.whereType<Map<String, dynamic>>().map(BookModel.fromJson).toList();
    } else {
      _errorMessage = response.message ?? 'বই লোড করা যায়নি';
    }
    notifyListeners();
  }

  Future<void> fetchBookshelf() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _bookshelf = [];
      _myBooks = [];
      return;
    }

    final response = await ApiService.get(ApiEndpoints.bookshelf);
    if (response.success && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final rawShelves = (data['shelves'] ?? data['bookshelf'] ?? []) as List;
        _bookshelf = rawShelves.whereType<Map<String, dynamic>>().map((shelf) {
          final bookMap = shelf['book'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(shelf['book'] as Map<String, dynamic>)
              : Map<String, dynamic>.from(shelf);
          if (shelf['last_read_page'] != null) {
            bookMap['last_read_page'] = shelf['last_read_page'];
          }
          bookMap['in_bookshelf'] = true;
          bookMap['has_access'] = true;
          return BookModel.fromJson(bookMap);
        }).toList();

        if (data['my_books'] is List) {
          _myBooks = (data['my_books'] as List).whereType<Map<String, dynamic>>().toList();
        }
        if (data['upload_quota'] is Map<String, dynamic>) {
          _uploadQuota = data['upload_quota'] as Map<String, dynamic>;
        }
      } else if (response.data is List) {
        _bookshelf = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(BookModel.fromJson)
            .toList();
      }
      notifyListeners();
    }
  }

  Future<void> fetchBookDetails(dynamic identifier) async {
    _isLoading = true;
    _selectedBook = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.bookDetails(identifier.toString()));
    if (response.success && response.data != null) {
      final bookData = response.data['book'] ?? response.data;
      if (bookData is Map<String, dynamic>) {
        var book = BookModel.fromJson(bookData);
        final chRes = await ApiService.get(ApiEndpoints.bookChapters(book.id));
        if (chRes.success && chRes.data is Map<String, dynamic>) {
          final chData = chRes.data as Map<String, dynamic>;
          final rawChapters = chData['chapters'] as List? ?? [];
          final chapters = rawChapters
              .whereType<Map<String, dynamic>>()
              .map(ChapterModel.fromJson)
              .toList();
          book = book.copyWith(
            chapters: chapters,
            hasAccess: chData['has_full_access'] == true || book.hasAccess,
            chapterPurchaseEnabled: chData['chapter_purchase_enabled'] == true,
          );
        }
        _selectedBook = book;
      }
    } else {
      _errorMessage = response.message ?? 'বইয়ের বিবরণ লোড করা যায়নি';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<ApiResponse> addToBookshelf(BookModel book) async {
    _isActionLoading = true;
    notifyListeners();
    final response = await ApiService.post(ApiEndpoints.addToShelf(book.id));
    _isActionLoading = false;
    if (response.success) {
      _selectedBook = _selectedBook?.copyWith(inBookshelf: true);
      await fetchBookshelf();
    }
    notifyListeners();
    return response;
  }

  Future<Map<String, dynamic>> purchaseBook({
    required int bookId,
    required String paymentMethod,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    final response = await ApiService.post(
      ApiEndpoints.purchaseBook(bookId),
      body: {'payment_method': paymentMethod},
    );

    _isActionLoading = false;
    if (response.success) {
      await fetchBookDetails(_selectedBook?.slug ?? bookId);
      await fetchBookshelf();
      return {
        'success': true,
        'redirect_url': response.data is Map ? response.data['redirect_url'] : null,
        'message': response.message ?? 'বই ক্রয় সফল হয়েছে!',
      };
    }
    notifyListeners();
    return {
      'success': false,
      'message': response.message ?? 'বই ক্রয় সম্পন্ন করা যায়নি।',
    };
  }

  Future<Map<String, dynamic>> purchaseChapters({
    required int bookId,
    required List<int> chapterIds,
    String paymentMethod = 'wallet',
  }) async {
    _isActionLoading = true;
    notifyListeners();

    final response = await ApiService.post(
      ApiEndpoints.purchaseChapters(bookId),
      body: {
        'chapter_ids': chapterIds,
        'payment_method': paymentMethod,
      },
    );

    _isActionLoading = false;
    if (response.success) {
      await fetchBookDetails(_selectedBook?.slug ?? bookId);
      await fetchBookshelf();
      return {
        'success': true,
        'redirect_url': response.data is Map ? response.data['redirect_url'] : null,
        'message': response.message ?? 'অধ্যায় ক্রয় সম্পন্ন হয়েছে!',
      };
    }
    notifyListeners();
    return {
      'success': false,
      'message': response.message ?? 'ক্রয় সম্পন্ন করা যায়নি। ওয়ালেট ব্যালেন্স চেক করুন।',
    };
  }

  Future<bool> deleteMyBook(int myBookId) async {
    final res = await ApiService.delete(ApiEndpoints.deleteMyBook(myBookId));
    if (res.success) {
      await fetchBookshelf();
      return true;
    }
    return false;
  }
}
