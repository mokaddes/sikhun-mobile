import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      await fetchProfile();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );

    _isLoading = false;
    if (response.success && response.data != null) {
      final token = response.data['token'] ?? response.data['access_token'];
      if (token != null) {
        await ApiService.setToken(token.toString());
      }
      if (response.data['user'] != null) {
        _user = UserModel.fromJson(response.data['user']);
      } else {
        await fetchProfile();
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'লগইন ব্যর্থ হয়েছে। তথ্য যাচাই করুন।';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? studentType,
    String? educationLevel,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(
      ApiEndpoints.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone,
        'student_type': studentType,
        'education_level': educationLevel,
      },
    );

    _isLoading = false;
    if (response.success && response.data != null) {
      final token = response.data['token'] ?? response.data['access_token'];
      if (token != null) {
        await ApiService.setToken(token.toString());
      }
      if (response.data['user'] != null) {
        _user = UserModel.fromJson(response.data['user']);
      } else {
        await fetchProfile();
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'রেজিস্ট্রেশন সম্পন্ন করা যায়নি।';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    final response = await ApiService.get(ApiEndpoints.me);
    if (response.success && response.data != null) {
      final userData = response.data['user'] ?? response.data;
      _user = UserModel.fromJson(userData);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post(ApiEndpoints.logout);
    } catch (_) {}
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
