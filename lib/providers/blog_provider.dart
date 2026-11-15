import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/blog_model.dart';
import '../services/api_service.dart';

class BlogProvider extends ChangeNotifier {
  List<BlogModel> _blogs = [];
  List<String> _categories = [];
  BlogModel? _selectedBlog;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;

  List<BlogModel> get blogs => _blogs;
  List<String> get categories => _categories;
  BlogModel? get selectedBlog => _selectedBlog;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;

  Future<void> init() async {
    await fetchCategories();
    await fetchBlogs();
  }

  Future<void> fetchCategories() async {
    final response = await ApiService.get(ApiEndpoints.blogCategories);
    if (response.success && response.data != null) {
      if (response.data is List) {
        _categories = (response.data as List).map((c) {
          if (c is Map) return c['name']?.toString() ?? '';
          return c.toString();
        }).where((c) => c.isNotEmpty).toList();
      }
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    _selectedCategory = (category == null || category == 'all') ? null : category;
    fetchBlogs(category: _selectedCategory);
  }

  Future<void> fetchBlogs({String? category, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await ApiService.get(ApiEndpoints.blogs, queryParams: query);
    _isLoading = false;

    if (response.success && response.data != null) {
      final list = (response.data is List)
          ? response.data as List
          : (response.data['blogs'] ?? response.data['data'] ?? []) as List;
      _blogs = list.map((json) => BlogModel.fromJson(json)).toList();
    } else {
      _errorMessage = response.message ?? 'ব্লগ লোড করা যায়নি';
    }
    notifyListeners();
  }

  Future<void> fetchBlogDetails(String slug) async {
    _isLoading = true;
    _selectedBlog = null;
    notifyListeners();

    final response = await ApiService.get(ApiEndpoints.blogDetails(slug));
    _isLoading = false;

    if (response.success && response.data != null) {
      final blogData = response.data['post'] ?? response.data['blog'] ?? response.data;
      _selectedBlog = BlogModel.fromJson(blogData);
    } else {
      _errorMessage = response.message ?? 'ব্লগের বিবরণ লোড করা যায়নি';
    }
    notifyListeners();
  }
}
