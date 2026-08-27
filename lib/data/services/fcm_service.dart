import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Service for receiving and handling Firebase Cloud Messaging push notifications.
///
/// Usage:
/// - Call [init] once at app startup (after Firebase.initializeApp).
/// - Subscribe to [onMessage] / [onTokenRefresh] as needed.
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Token for the current device. Null until [init] completes.
  String? currentToken;

  /// Stream of foreground messages (app is open).
  Stream<RemoteMessage> get onMessage => _messaging.onMessage;

  /// Stream of token refresh events.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Initialise notifications: request permission, get token, listen for messages.
  Future<void> init() async {
    // Request permission (Android 13+ requires explicit request).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false,
      provisional: false,
      announcement: false,
      carPlay: false,
    );

    // Get the device FCM token.
    currentToken = await _messaging.getToken();
    // TODO: send currentToken to your backend so it can target this device.

    // Listen for token changes (e.g. after app reinstall).
    _messaging.onTokenRefresh.listen((newToken) {
      currentToken = newToken;
      // TODO: update token on backend.
    });

    // Foreground message handler (app is open).
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message handler (registered globally below).
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // User tapped notification while app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // The system notification is NOT shown automatically in foreground.
    // Use flutter_local_notifications to show an in-app banner.
    print('[FCM] Foreground: ${message.notification?.title}');
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to a specific screen based on message data.
    print('[FCM] Opened app from notification: ${message.data}');
  }

  /// Subscribe to a topic.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Delete the current token (e.g. on logout).
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    currentToken = null;
  }
}

/// Top-level function for background message handling.
/// Must be a top-level function (not a class method) for FCM to call it.
@pragma('vm:entry-point')
Future<void> fcmBackgroundMessageHandler(RemoteMessage message) async {
  print('[FCM] Background: ${message.notification?.title}');
}

// ────────────────────────────────────────────────────────────────
// Server-side helper: send a test push via FCM Legacy HTTP API.
// This is a convenience function for backend / scripts.
// ────────────────────────────────────────────────────────────────

/// Send a push notification via Firebase Cloud Messaging Legacy API.
///
/// Returns `true` if the request was accepted (HTTP 200).
Future<bool> sendFcmPush({
  required String fcmServerKey,
  required String deviceToken,
  required String title,
  required String body,
  Map<String, String>? data,
}) async {
  final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
  final client = HttpClient();
  final request = await client.postUrl(uri);
  request.headers
    ..set('Content-Type', 'application/json')
    ..set('Authorization', 'key=$fcmServerKey');

  final payload = {
    'to': deviceToken,
    'notification': {'title': title, 'body': body, 'sound': 'default'},
    if (data != null) 'data': data,
    'priority': 'high',
    'android': {'priority': 'high'},
    'apns': {'payload': {'aps': {'sound': 'default'}}},
  };

  request.write(jsonEncode(payload));
  final response = await request.close();
  client.close();
  return response.statusCode == 200;
}
