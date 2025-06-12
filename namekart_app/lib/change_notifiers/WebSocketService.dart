import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
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
  static String? userId;

  // Stream to listen for broadcast messages
  static Stream<String> get onBroadcastMessage => _broadcastController.stream;

  // Stream to listen for user-specific messages
  static Stream<String> get onUserMessage => _userController.stream;

  // Check if WebSocket is connected
  // Connect to the WebSocket server with the userId
  Future<void> connect(
      String userId,
      LiveDatabaseChange liveDatabaseChange,
      LiveListDatabaseChange liveListDatabaseChange,
      NotificationDatabaseChange notificationDatabaseChange,
      NewNotificationTableAddNotifier newNotificationTableAddNotifier,
      DatabaseDataUpdatedNotifier databaseDataUpdatedNotifier,
      NotifyRebuildChange notifyRebuildChange) async {
    if (userId.isEmpty) {
      print("User ID is required to connect.");
      return;
    }

    // Close any existing connection before opening a new one
    if (isConnected) {
      print("Closing previous WebSocket connection...");
      await disconnect();
    }

    try {
      print("Connecting to WebSocket with userId: $userId");
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://nk-phone-app-helper-microservice.politesky-7d4012d0.westus.azurecontainerapps.io/websocket/auctions?userId=$userId'),
      );

      print("object ${_channel.toString()}");

      _channel.stream.listen(
        (message) async {
          print("Received WebSocket message: $message");


          Map<String, dynamic> jsonMessage = jsonDecode(message);

          if (jsonMessage["type"] == "broadcast") {
            Map<String, dynamic> data = jsonDecode(jsonMessage["data"]);
            String path = jsonMessage["path"];

            HiveHelper.addDataToHive(path, data['id'].toString(),data);

            if(path.contains("live")) {
              liveDatabaseChange.notifyLiveDatabaseChange(path);

              HiveHelper.addDataToHive("live~all~auctions", data['id'].toString(), data);
            }else if(path.contains("notifications")){
              liveDatabaseChange.notifyLiveDatabaseChange(path);
              notificationDatabaseChange.notifyNotificationDatabaseChange();
            }
          }
          else if(jsonMessage["type"] == "broadcast-update") {
            _broadcastController.add(message);
            Map<String, dynamic> data = jsonDecode(jsonMessage["data"]);
            String path = jsonMessage["path"];
            HiveHelper.updateDataOfHive(path, data['id'].toString(),data);
            databaseDataUpdatedNotifier.notifyDatabaseDataUpdated(path);

          }
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

      notifyListeners();
    } catch (e) {
      print("Failed to connect to WebSocket: $e");
      isConnected = false;
      notifyListeners();
    }
  }

  // Send a message to the WebSocket server
  void sendMessage(Map<String, dynamic> message) {
    try {
      String jsonMessage = jsonEncode(message);
      _channel.sink.add(jsonMessage);
      print("Sent message: $jsonMessage");
    } catch (e) {
      print("Failed to send message: $e");
    }
  }

  Future<Map<String, dynamic>> sendMessageGetResponse(
      Map<String, dynamic> messageToSend,
      String type, {
        required String expectedQuery,
      }) async {
    final completer = Completer<Map<String, dynamic>>();

    StreamSubscription? subscription;

    void retrieveData(String data) {
      try {
        print("Received WebSocket message: $data"); // Log raw message
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final innerData = jsonDecode(decoded['data'] as String) as Map<String, dynamic>;
          print("Decoded inner data: $innerData"); // Log decoded data
          if (innerData['query'] == expectedQuery) {
            print("Query match for '$expectedQuery'. Completing with response: ${decoded}");
            completer.complete(decoded); // Return the full WebSocket message
            subscription?.cancel();
          } else {
            print("Query mismatch. Expected: '$expectedQuery', Got: '${innerData['query']}'");
          }
        } else {
          print("Invalid WebSocket message format: $data");
        }
      } catch (e, stackTrace) {
        print("Error decoding message: $e\n$stackTrace");
      }
    }

    try {
      // Validate WebSocket connection


      // Subscribe to the appropriate stream
      if (type == "broadcast") {
        subscription = onBroadcastMessage.listen(retrieveData);
      } else if (type == "user") {
        subscription = onUserMessage.listen(retrieveData);
      } else {
        throw ArgumentError("Invalid type: $type. Must be 'broadcast' or 'user'.");
      }

      // Send the message
      print("Sending message: $messageToSend for query: $expectedQuery");
      sendMessage(messageToSend);
    } catch (e, stackTrace) {
      print("Error sending message: $e\n$stackTrace");
      subscription?.cancel();
      completer.completeError(Exception("Failed to send message: $e"));
      return completer.future;
    }

    // Return the future with a timeout
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print("Timeout waiting for response for query '$expectedQuery'");
        subscription?.cancel();
        throw TimeoutException("No response for query '$expectedQuery' within 10 seconds.");
      },
    );
  }

  // Close the WebSocket connection
  Future<void> disconnect() async {
    await _channel.sink.close();
    isConnected = false;
    notifyListeners();

    // Do not close the database here!
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
