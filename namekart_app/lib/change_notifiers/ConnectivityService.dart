import 'dart:async';

import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
  bool _isConnected = false;
  late final StreamSubscription<InternetConnectionStatus> _connectionSubscription;

  bool get isConnected => _isConnected;

  ConnectivityService() {
    _startListeningToConnectivity();
  }

  // Start listening to connectivity changes
  void _startListeningToConnectivity() {
    // Use the createInstance method to initialize the checker
    _connectionSubscription = InternetConnectionChecker.createInstance().onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        _isConnected = true;  // Internet restored
        notifyListeners();
      } else {
        _isConnected = false;  // Internet lost
        notifyListeners();
      }
    });
  }

  // Don't forget to cancel the subscription when the service is disposed
  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}