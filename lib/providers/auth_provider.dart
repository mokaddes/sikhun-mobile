import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_endpoints.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/firebase_push_service.dart';

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
      if (_user != null) {
        FirebasePushService.instance.syncIfAuthenticated();
      }
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
      final rawStudent = response.data['student'] ?? response.data['user'];
      if (rawStudent is Map<String, dynamic>) {
        _user = UserModel.fromJson(rawStudent);
      } else {
        await fetchProfile();
      }
      FirebasePushService.instance.syncIfAuthenticated();
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
    String studentType = 'admission',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedType = studentType.toLowerCase();
    final response = await ApiService.post(
      ApiEndpoints.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'type': normalizedType,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    _isLoading = false;
    if (response.success && response.data != null) {
      final token = response.data['token'] ?? response.data['access_token'];
      if (token != null) {
        await ApiService.setToken(token.toString());
      }
      final rawStudent = response.data['student'] ?? response.data['user'];
      if (rawStudent is Map<String, dynamic>) {
        _user = UserModel.fromJson(rawStudent);
      } else {
        await fetchProfile();
      }
      FirebasePushService.instance.syncIfAuthenticated();
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
      final userData = response.data['student'] ?? response.data['user'] ?? response.data;
      if (userData is Map<String, dynamic>) {
        _user = UserModel.fromJson(userData);
        notifyListeners();
      }
    } else if (response.statusCode == 401) {
      await ApiService.clearToken();
      _user = null;
      notifyListeners();
    }
  }

  Future<ApiResponse> updateProfile({
    String? name,
    String? phone,
    String? institution,
    String? type,
  }) async {
    _isLoading = true;
    notifyListeners();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (institution != null) body['institution'] = institution;
    if (type != null) body['type'] = type.toLowerCase();

    final response = await ApiService.put(ApiEndpoints.profile, body: body);
    _isLoading = false;
    if (response.success && response.data is Map<String, dynamic>) {
      _user = UserModel.fromJson(response.data as Map<String, dynamic>);
    }
    notifyListeners();
    return response;
  }

  Future<ApiResponse> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    return ApiService.put(
      ApiEndpoints.updatePassword,
      body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<ApiResponse> updateLeaderboardOptOut(bool optOut) async {
    final res = await ApiService.put(
      ApiEndpoints.updateLeaderboardOptOut,
      body: {'leaderboard_opt_out': optOut},
    );
    if (res.success && res.data is Map<String, dynamic>) {
      _user = UserModel.fromJson(res.data as Map<String, dynamic>);
      notifyListeners();
    }
    return res;
  }

  Future<ApiResponse> forgotPassword(String email) async {
    return ApiService.post(ApiEndpoints.forgotPassword, body: {'email': email});
  }

  Future<ApiResponse> sendVerificationEmail() async {
    return ApiService.post(ApiEndpoints.sendVerification);
  }

  /// Production Google OAuth sign-in -> exchanges Google access token for Sanctum token.
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Google অ্যাক্সেস টোকেন পাওয়া যায়নি। আবার চেষ্টা করুন।';
        notifyListeners();
        return false;
      }

      final response = await ApiService.post(
        ApiEndpoints.googleOAuthExchange,
        body: {'access_token': accessToken},
      );

      _isLoading = false;
      if (response.success && response.data != null) {
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) {
          await ApiService.setToken(token.toString());
        }
        final rawStudent = response.data['student'] ?? response.data['user'];
        if (rawStudent is Map<String, dynamic>) {
          _user = UserModel.fromJson(rawStudent);
        } else {
          await fetchProfile();
        }
        FirebasePushService.instance.syncIfAuthenticated();
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Google লগইন ব্যর্থ হয়েছে।';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google লগইন সম্পন্ন করা যায়নি: $e';
      notifyListeners();
      return false;
    }
  }

  /// Schedules 30-day soft account deletion (Facebook-style recovery window).
  Future<ApiResponse> deleteAccount() async {
    final res = await ApiService.delete(
      ApiEndpoints.deleteAccount,
      body: {'confirmation': 'DELETE'},
    );
    if (res.success) {
      await ApiService.clearToken();
      _user = null;
      notifyListeners();
    }
    return res;
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
