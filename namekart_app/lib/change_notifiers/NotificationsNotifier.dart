import 'package:flutter/cupertino.dart';

class NotificationsNotifier extends ChangeNotifier{
  void notifyNotifications() {
    notifyListeners();
  }
}