import 'dart:async';
import 'package:flutter/material.dart';
import '../config/api_endpoints.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _pollingTimer;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void startSync() {
    fetchNotifications();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      fetchNotifications(silent: true);
    });
  }

  void stopSync() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _notifications = [];
      _unreadCount = 0;
      if (!silent) notifyListeners();
      return;
    }

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    final response = await ApiService.get(ApiEndpoints.notifications);
    _isLoading = false;

    if (response.success && response.data != null) {
      final data = response.data;
      final rawItems = (data['items'] is Map && data['items']['data'] is List)
          ? data['items']['data'] as List
          : (data['items'] is List
              ? data['items'] as List
              : (data['data'] is List ? data['data'] as List : []));

      _notifications = rawItems.whereType<Map<String, dynamic>>().map(NotificationModel.fromJson).toList();
      _unreadCount = data['unread_count'] is int
          ? data['unread_count']
          : int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;
    }

    notifyListeners();
  }

  Future<bool> markAsRead(int notificationId) async {
    final response = await ApiService.put(
      ApiEndpoints.notificationMarkRead(notificationId),
    );
    if (response.success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final old = _notifications[index];
        _notifications[index] = NotificationModel(
          id: old.id,
          title: old.title,
          body: old.body,
          type: old.type,
          data: old.data,
          readAt: DateTime.now(),
          createdAt: old.createdAt,
        );
      }
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    final response = await ApiService.put(ApiEndpoints.notificationsMarkAllRead);
    if (response.success) {
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          data: n.data,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteNotification(int id) async {
    final response = await ApiService.delete(ApiEndpoints.notificationDelete(id));
    if (response.success) {
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> registerPushToken(String pushToken) async {
    if (pushToken.isEmpty) return;
    try {
      await ApiService.post(
        ApiEndpoints.registerFcmToken,
        body: {'fcm_token': pushToken},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
