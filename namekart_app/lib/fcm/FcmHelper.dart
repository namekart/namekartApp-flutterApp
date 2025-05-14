import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Background FCM handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FCMHelper().showNotification(message);
}

class FCMHelper {
  static final FCMHelper _instance = FCMHelper._internal();
  factory FCMHelper() => _instance;
  FCMHelper._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for critical notifications.',
    importance: Importance.max,
  );

  /// Initialize FCM and notification handling
  Future<void> initializeFCM() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _setupNotificationChannel();
    await _initializeLocalNotifications();
    _setupMessageListeners();

    _initialized = true;
    print("✅ FCM Initialized");
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    if (topic.trim().isEmpty) return;
    await _messaging.subscribeToTopic(topic);
    print("✅ Subscribed to topic: $topic");
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (topic.trim().isEmpty) return;
    await _messaging.unsubscribeFromTopic(topic);
    print("❌ Unsubscribed from topic: $topic");
  }

  /// Get FCM token (optional)
  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  /// Show notification with data
  Future<void> showNotification(RemoteMessage message) async {
    String title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    String body = message.notification?.body ?? message.data['body'] ?? '';
    String payload = message.data.toString();

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("🔔 Permission status: ${settings.authorizationStatus}");
  }

  /// Create Android notification channel
  Future<void> _setupNotificationChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'accept') {
          print("✅ User accepted");
          // Add accept logic here
        } else if (response.actionId == 'reject') {
          print("❌ User rejected");
          // Add reject logic here
        }
      },
    );
  }

  /// Handle messages (foreground, background tap, terminated)
  void _setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("📩 Foreground message: ${message.data}");
      await showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 Notification opened: ${message.data}");
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("🚀 Launched from terminated: ${message.data}");
      }
    });
  }
}
