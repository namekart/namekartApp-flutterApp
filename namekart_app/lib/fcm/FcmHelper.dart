import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMHelper {
  static final FCMHelper _instance = FCMHelper._internal();
  factory FCMHelper() => _instance;
  FCMHelper._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initializeFCM() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    await _messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    _initialized = true;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    // No Dart-side notification shown
  }
}
