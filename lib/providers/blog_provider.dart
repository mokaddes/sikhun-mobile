import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/blog_model.dart';
import '../services/api_service.dart';

class BlogCategoryItem {
  final String name;
  final String slug;

  BlogCategoryItem({required this.name, required this.slug});
}

class BlogProvider extends ChangeNotifier {
  List<BlogModel> _blogs = [];
  List<BlogCategoryItem> _categories = [];
  BlogModel? _selectedBlog;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategorySlug;

  List<BlogModel> get blogs => _blogs;
  List<BlogCategoryItem> get categories => _categories;
  BlogModel? get selectedBlog => _selectedBlog;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategorySlug;

  Future<void> init() async {
    await fetchBlogs();
  }

  void setCategory(String? categorySlug) {
    _selectedCategorySlug = (categorySlug == null || categorySlug == 'all') ? null : categorySlug;
    fetchBlogs(category: _selectedCategorySlug);
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
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['posts'] ?? data['blogs'] ?? data['data'] ?? []) as List;
        _blogs = list.whereType<Map<String, dynamic>>().map(BlogModel.fromJson).toList();

        if (data['categories'] is List) {
          _categories = (data['categories'] as List)
              .whereType<Map<String, dynamic>>()
              .map((c) => BlogCategoryItem(
                    name: (c['name_bn'] ?? c['name_en'] ?? c['name'] ?? '').toString(),
                    slug: (c['slug'] ?? '').toString(),
                  ))
              .where((c) => c.name.isNotEmpty && c.slug.isNotEmpty)
              .toList();
        }
      } else if (response.data is List) {
        _blogs = (response.data as List).whereType<Map<String, dynamic>>().map(BlogModel.fromJson).toList();
      }
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
      if (blogData is Map<String, dynamic>) {
        _selectedBlog = BlogModel.fromJson(blogData);
      }
    } else {
      _errorMessage = response.message ?? 'ব্লগের বিবরণ লোড করা যায়নি';
    }
    notifyListeners();
  }
}
