import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/change_notifiers/AllDatabaseChangeNotifiers.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService with ChangeNotifier {
  static late WebSocketChannel _channel;
  static final StreamController<String> _broadcastController =
      StreamController<String>.broadcast();
  static final StreamController<String> _userController =
      StreamController<String>.broadcast();
  static bool isConnected = false;

  // 🔁 Holds all pending queries waiting for a response
  static final Map<String, List<Completer<Map<String, dynamic>>>>
      _pendingQueries = {};

  static Stream<String> get onBroadcastMessage => _broadcastController.stream;

  static Stream<String> get onUserMessage => _userController.stream;

  Future<void> connect(
    String userId,
    LiveDatabaseChange liveDatabaseChange,
    ReconnectivityNotifier reconnectivityNotifier,
    NotificationDatabaseChange notificationDatabaseChange,
    CheckConnectivityNotifier checkConnectivityNotifier,
    DatabaseDataUpdatedNotifier databaseDataUpdatedNotifier,
    BubbleButtonClickUpdateNotifier bubbleButtonClickUpdateNotifier,
      NotificationPathNotifier notificationPathNotifier
  ) async {
    if (userId.isEmpty) {
      print("User ID is required to connect.");
      return;
    }

    if (isConnected) {
      print("Closing previous WebSocket connection...");
      await disconnect();
    }

    try {
      print("Connecting to WebSocket with userId: $userId");
      _channel = WebSocketChannel.connect(
        Uri.parse(
          'ws://nk-phone-app-helper-microservice.politesky-7d4012d0.westus.azurecontainerapps.io/websocket/auctions?userId=$userId',
        ),
      );

      _channel.stream.listen(
        (message) async {
          print("Received WebSocket message: $message");

          final jsonMessage = jsonDecode(message);

          print(jsonMessage);

          // ✅ Handle broadcast messages
          if (jsonMessage["type"] == "broadcast") {
            Map<String, dynamic> data = jsonDecode(jsonMessage["data"]);
            String path = jsonMessage["path"];

            HiveHelper.addDataToHive(
                path, data['datetime_id'].toString(), data);

            if (path.contains("live")) {
              liveDatabaseChange.notifyLiveDatabaseChange(path);
              HiveHelper.addDataToHive(
                  "live~all~auctions", data['datetime_id'].toString(), data);
            } else if (path.contains("notifications")) {
              liveDatabaseChange.notifyLiveDatabaseChange(path);
              notificationDatabaseChange.notifyNotificationDatabaseChange();
            }

            _broadcastController.add(message);
          }

          // ✅ Handle broadcast updates
          else if (jsonMessage["type"] == "broadcast-update") {
            Map<String, dynamic> data = jsonDecode(jsonMessage["data"]);
            String path = jsonMessage["path"];

            HiveHelper.updateDataOfHive(path, data['datetime_id'].toString(), data);
            databaseDataUpdatedNotifier.notifyDatabaseDataUpdated(path);
            bubbleButtonClickUpdateNotifier.notifyBubbleButtonClickUpdateNotifier();

            _broadcastController.add(message);
          }

          // ✅ Handle request-response logic (user message)

          else if(jsonMessage.toString().contains("check-connection")){
            checkConnectivityNotifier.notifyCheckConnectivityNotifier();
          }

          else if(jsonMessage.toString().contains("reconnection-check")){
            reconnectivityNotifier.notifyReconnectivityNotifier();
          }
          else if(jsonMessage.toString().contains("firebase-all_collection_info")){
            await addAllCloudPath(message);
            notificationPathNotifier.notifyNotificationPathNotifier();
          }

          // Handle anything else (fallback to user stream)
          else {
            _userController.add(message);
          }
        },
        onError: (error) {
          print("WebSocket error: $error");
          isConnected = false;
          notifyListeners();
        },
        onDone: () {
          print("WebSocket connection closed");
          isConnected = false;
          notifyListeners();
        },
      );

      isConnected = true;
      notifyListeners();
    } catch (e) {
      print("Failed to connect to WebSocket: $e");
      isConnected = false;
      notifyListeners();
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    try {
      final jsonMessage = jsonEncode(message);
      _channel.sink.add(jsonMessage);
      print("Sent message: $jsonMessage");
    } catch (e) {
      print("Failed to send message: $e");
    }
  }

  Future<void> disconnect() async {
    await _channel.sink.close();
    isConnected = false;
    notifyListeners();
    print("WebSocket disconnected. Database remains open.");
  }

  @override
  void dispose() {
    _broadcastController.close();
    _userController.close();
    _channel.sink.close();
    super.dispose();
  }
}
