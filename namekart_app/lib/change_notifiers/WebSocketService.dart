import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:namekart_app/activity_helpers/DbSqlHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:namekart_app/activity_helpers/NotificationSettingsHelper.dart';
import 'package:namekart_app/change_notifiers/AllDatabaseChangeNotifiers.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
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

  bool showDialogCatched=false;
  bool updatedQueued=false;

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

  Future<void> connect(
      String userId,
      LiveDatabaseChange liveDatabaseChange,
      ReconnectivityNotifier reconnectivityNotifier,
      NotificationDatabaseChange notificationDatabaseChange,
      CheckConnectivityNotifier checkConnectivityNotifier,
      DatabaseDataUpdatedNotifier databaseDataUpdatedNotifier,
      BubbleButtonClickUpdateNotifier bubbleButtonClickUpdateNotifier,
      NotificationPathNotifier notificationPathNotifier,
      SnackBarSuccessNotifier snackBarSuccessNotifier,
      SnackBarFailedNotifier snackBarFailedNotifier,
      ShowDialogNotifier showDialogNotifier) async {
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
          'wss://nk-phone-app-helper-microservice.grayriver-ffcf7337.westus.azurecontainerapps.io/websocket/auctions?userId=$userId',
          // 'ws://192.168.1.7:8080/websocket/auctions?userId=$userId',
        ),
      );

      _channel.stream.listen((message) async {
          print("Received WebSocket message: $message");

          final jsonMessage = jsonDecode(message);

          print(jsonMessage);

          // ✅ Handle broadcast messages
          if (jsonMessage["type"] == "broadcast") {
            Map<String, dynamic> data = jsonDecode(jsonMessage["data"]);
            String path = jsonMessage["path"];

            DbSqlHelper.addData(path, data['datetime_id'].toString(), data);
            if(!await NotificationSettingsHelper.isNotificationPathManaged(userId,path)){
              FCMHelper().subscribeToTopic(path);
            }

            if (path.contains("live")) {
              liveDatabaseChange.notifyLiveDatabaseChange(path);
              DbSqlHelper.addData("live~all~auctions", data['datetime_id'].toString(), data);
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
            String query = jsonMessage["query"];


            updatedQueued=true;
            await DbSqlHelper.updateData(path, data['datetime_id'], data);
            updatedQueued=false;
            if(showDialogCatched){
              showDialogNotifier.notifyShowDialogNotifier();
              showDialogCatched=false;
            }



            databaseDataUpdatedNotifier.setPathOfUpdatedDocument(path);
            databaseDataUpdatedNotifier.notifyDatabaseDataUpdated(path);

            bubbleButtonClickUpdateNotifier.notifyBubbleButtonClickUpdateNotifier();

            _broadcastController.add(message);
          }

          // ✅ Handle request-response logic (user message)

          else if (jsonMessage.toString().contains("check-connection")) {
            checkConnectivityNotifier.notifyCheckConnectivityNotifier();
          } else if (jsonMessage.toString().contains("reconnection-check")) {
            reconnectivityNotifier.notifyReconnectivityNotifier();
          } else if (jsonMessage
              .toString()
              .contains("firebase-all_collection_info")) {
            await addAllCloudPath(message);
            notificationPathNotifier.notifyNotificationPathNotifier();
          } else if (jsonMessage.toString().contains("showSuccessSnackbar")) {
            snackBarSuccessNotifier.notifySnackBarSuccessNotifier(jsonDecode(jsonMessage["data"])['message']);
          } else if (jsonMessage.toString().contains("showFailedSnackbar")) {
            snackBarFailedNotifier.notifySnackBarFailedNotifier(jsonDecode(jsonDecode(jsonMessage["data"])['message'])['message']);
          } else if (jsonMessage.toString().contains("showWarningSnackbar")) {
            snackBarFailedNotifier.notifySnackBarFailedNotifier(jsonDecode(jsonMessage["data"])['message']['message']);
          } else if(jsonMessage.toString().contains("showDialog")){
            if(!updatedQueued) {
              showDialogNotifier.notifyShowDialogNotifier();
            }else{
              showDialogCatched=true;
            }

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

  @override
  void dispose() {
    _broadcastController.close();
    _userController.close();
    _channel.sink.close();
    super.dispose();
  }
}
