import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_endpoints.dart';
import '../config/firebase_options.dart';
import 'api_service.dart';

/// Top-level background handler required by firebase_messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (_) {}
}

class FirebasePushService {
  FirebasePushService._();
  static final FirebasePushService instance = FirebasePushService._();

  static const String _optOutKey = 'sikhun_fcm_opt_out';
  static const String _tokenKey = 'sikhun_fcm_token';
  static const String _channelId = 'sikhun_high_importance';

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  VoidCallback? onForegroundMessageReceived;

  Future<bool> isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default enabled for all new users; they can toggle it off in Profile Settings.
    return !(prefs.getBool(_optOutKey) ?? false);
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Setup high-importance Android notification channel + local notification tap handler
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (details) {
          final payloadUrl = details.payload;
          if (payloadUrl != null && payloadUrl.isNotEmpty) {
            openNotificationLink(payloadUrl);
          }
        },
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        'Sikhun Important Notifications',
        description: 'Admission notices, job circulars, renewal invoices, offers and exam alerts.',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Foreground push display
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (!await isPushEnabled()) return;

        final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Sikhun.com';
        final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
        final actionUrl = message.data['url']?.toString() ?? message.data['action_url']?.toString() ?? '';

        await _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'Sikhun Important Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          ),
          payload: actionUrl,
        );

        onForegroundMessageReceived?.call();
      });

      // Handle notification tap when app is in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpen(initialMessage);
      }

      // Auto-sync refreshed tokens
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (await isPushEnabled()) {
          await _syncTokenToBackend(newToken);
        }
      });

      // Request permission & sync if logged in and not opted out
      if (await isPushEnabled()) {
        await syncIfAuthenticated();
      }
    } catch (e) {
      debugPrint('FirebasePushService init skipped: $e');
    }
  }

  Future<void> syncIfAuthenticated() async {
    try {
      if (!await isPushEnabled()) return;
      final authToken = await ApiService.getToken();
      if (authToken == null || authToken.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final fcmToken = await messaging.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _syncTokenToBackend(fcmToken);
        }
      }
    } catch (e) {
      debugPrint('FCM sync error: $e');
    }
  }

  Future<bool> setPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optOutKey, !enabled);

    if (enabled) {
      await syncIfAuthenticated();
      return true;
    } else {
      try {
        final savedToken = prefs.getString(_tokenKey) ?? '';
        await ApiService.delete(
          ApiEndpoints.unregisterFcmToken,
          body: savedToken.isNotEmpty ? {'fcm_token': savedToken} : null,
        );
        await FirebaseMessaging.instance.deleteToken();
        await prefs.remove(_tokenKey);
      } catch (e) {
        debugPrint('FCM disable error: $e');
      }
      return false;
    }
  }

  Future<void> _syncTokenToBackend(String fcmToken) async {
    final authToken = await ApiService.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final res = await ApiService.post(
      ApiEndpoints.registerFcmToken,
      body: {'fcm_token': fcmToken},
    );
    if (res.success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, fcmToken);
    }
  }

  void _handleNotificationOpen(RemoteMessage message) {
    final url = message.data['url']?.toString() ?? message.data['action_url']?.toString();
    if (url != null && url.isNotEmpty) {
      openNotificationLink(url);
    }
  }

  static Future<void> openNotificationLink(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    final resolved = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : '${ApiEndpoints.siteUrl}${trimmed.startsWith('/') ? trimmed : '/$trimmed'}';
    final uri = Uri.tryParse(resolved);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}
