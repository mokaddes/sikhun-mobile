import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<BookModel> _books = [];
  List<BookModel> _bookshelf = [];
  BookModel? _selectedBook;
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'all';

  List<BookModel> get books => _books;
  List<BookModel> get bookshelf => _bookshelf;
  BookModel? get selectedBook => _selectedBook;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  void setCategory(String category) {
    _selectedCategory = category;
    fetchBooks(category: category == 'all' ? null : category);
  }

  Future<void> fetchBooks({String? category, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'all') {
      query['category'] = category;
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
      _books = list.map((json) => BookModel.fromJson(json)).toList();
    } else {
      _errorMessage = response.message ?? 'বই লোড করা যায়নি';
    }
    notifyListeners();
  }

  Future<void> fetchBookshelf() async {
    final response = await ApiService.get(ApiEndpoints.bookshelf);
    if (response.success && response.data != null) {
      final list = (response.data is List)
          ? response.data as List
          : (response.data['bookshelf'] ?? response.data['data'] ?? []) as List;
      _bookshelf = list.map((json) => BookModel.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> fetchBookDetails(dynamic identifier) async {
    _isLoading = true;
    _selectedBook = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.bookDetails(identifier.toString()));
    _isLoading = false;

    if (response.success && response.data != null) {
      final bookData = response.data['book'] ?? response.data;
      _selectedBook = BookModel.fromJson(bookData);
    } else {
      _errorMessage = response.message ?? 'বইয়ের বিবরণ লোড করা যায়নি';
    }
    notifyListeners();
  }

  Future<bool> toggleBookshelf(BookModel book) async {
    _isActionLoading = true;
    notifyListeners();

    ApiResponse response;
    if (book.inBookshelf) {
      response = await ApiService.delete(ApiEndpoints.removeFromShelf(book.id));
    } else {
      response = await ApiService.post(ApiEndpoints.addToShelf(book.id));
    }

    _isActionLoading = false;
    if (response.success) {
      await fetchBookshelf();
      if (_selectedBook != null && _selectedBook!.id == book.id) {
        await fetchBookDetails(book.id);
      }
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> purchaseChapters({
    required int bookId,
    required List<int> chapterIds,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    final response = await ApiService.post(
      ApiEndpoints.purchaseChapters(bookId),
      body: {'chapter_ids': chapterIds},
    );

    _isActionLoading = false;
    if (response.success) {
      await fetchBookDetails(bookId);
      await fetchBookshelf();
      return {'success': true, 'message': response.message ?? 'অধ্যায় ক্রয় সম্পন্ন হয়েছে!'};
    } else {
      return {'success': false, 'message': response.message ?? 'ক্রয় সম্পন্ন করা যায়নি। ওয়ালেট ব্যালেন্স চেক করুন।'};
    }
  }
}
