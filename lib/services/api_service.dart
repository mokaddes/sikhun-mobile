import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int statusCode;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
    this.meta,
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

  static Future<Map<String, String>> _headers({String accept = 'application/json'}) async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': accept,
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _buildUri(String url, {Map<String, dynamic>? queryParams}) {
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      final Map<String, String> cleanParams = {};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanParams[key] = value.toString();
        }
      });
      if (cleanParams.isNotEmpty) {
        uri = uri.replace(queryParameters: cleanParams);
      }
    }
    return uri;
  }

  static Future<ApiResponse> get(String url, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(url, queryParams: queryParams);
      final response = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 45));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse> patch(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse> delete(String url) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        statusCode: 500,
      );
    }
  }

  /// Streams Server-Sent Events (SSE) from endpoints like /ai/chat/sessions/{id}/message
  /// or /reader/{book}/chat and yields parsed JSON payloads or raw text deltas.
  static Stream<Map<String, dynamic>> postSseStream(
    String url, {
    required Map<String, dynamic> body,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(await _headers(accept: 'text/event-stream'));
      request.body = jsonEncode(body);

      final streamed = await client.send(request).timeout(const Duration(seconds: 90));
      if (streamed.statusCode >= 400) {
        final rawBody = await streamed.stream.bytesToString();
        String errMsg = 'HTTP ${streamed.statusCode}';
        try {
          final parsed = jsonDecode(rawBody);
          if (parsed is Map && parsed['message'] != null) {
            errMsg = parsed['message'].toString();
          }
        } catch (_) {}
        yield {'error': errMsg, 'statusCode': streamed.statusCode};
        return;
      }

      String buffer = '';
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (buffer.contains('\n')) {
          final idx = buffer.indexOf('\n');
          final line = buffer.substring(0, idx).trim();
          buffer = buffer.substring(idx + 1);
          if (!line.startsWith('data:')) continue;
          final jsonStr = line.substring(5).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
          try {
            final parsed = jsonDecode(jsonStr);
            if (parsed is Map<String, dynamic>) {
              yield parsed;
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  static ApiResponse _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final bool isHttpOk = response.statusCode >= 200 && response.statusCode < 300;

      if (body is Map<String, dynamic>) {
        final bool success = body.containsKey('success') ? (body['success'] == true) : isHttpOk;
        String? message = body['message']?.toString();

        // Extract first Laravel validation error if present
        if (!success && body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
          final errorsMap = body['errors'] as Map;
          final firstVal = errorsMap.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = firstVal.first.toString();
          } else if (firstVal != null) {
            message = firstVal.toString();
          }
        }

        final data = body.containsKey('data') ? body['data'] : body;
        final meta = body['meta'] is Map<String, dynamic>
            ? body['meta'] as Map<String, dynamic>
            : null;

        return ApiResponse(
          success: success,
          data: data,
          message: message,
          statusCode: response.statusCode,
          meta: meta,
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
        message: response.body.length > 200 ? 'সার্ভার ত্রুটি (${response.statusCode})' : response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
