import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiService {
  static const String _tokenKey = 'sikhun_auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<ApiResponse> get(String url, {Map<String, dynamic>? queryParams}) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        final Map<String, dynamic> cleanParams = {};
        queryParams.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            cleanParams[key] = value.toString();
          }
        });
        uri = uri.replace(queryParameters: cleanParams);
      }

      final response = await http.get(uri, headers: await _headers());
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'কানেকশন সমস্যা: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'কানেকশন সমস্যা: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse> delete(String url) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _headers(),
      );
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'কানেকশন সমস্যা: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  static ApiResponse _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final bool isHttpOk = response.statusCode >= 200 && response.statusCode < 300;

      if (body is Map<String, dynamic>) {
        final bool success = body.containsKey('success')
            ? (body['success'] == true)
            : isHttpOk;
        final message = body['message']?.toString();
        final data = body.containsKey('data') ? body['data'] : body;

        return ApiResponse(
          success: success,
          data: data,
          message: message,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: isHttpOk,
          data: body,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
