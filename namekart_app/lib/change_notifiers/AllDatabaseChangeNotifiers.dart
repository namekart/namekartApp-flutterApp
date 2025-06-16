import 'package:flutter/cupertino.dart';

class LiveDatabaseChange extends ChangeNotifier {
  late String addedDatabasePath;
  late String currentDatabasePath = "";

  // This method will update the stored path and notify listeners
  void setPath(String path) {
    currentDatabasePath = path;
  }

  String getUpdatedPath() {
    return addedDatabasePath;
  }

  // This method will notify listeners if the path matches the one being updated
  void notifyLiveDatabaseChange(String path) {
    // If the updated path matches the current path, notify listeners
    addedDatabasePath = path;
    if (currentDatabasePath != "") {
      if (currentDatabasePath.contains(addedDatabasePath)) {
        notifyListeners();
      }
    }
  }
}

class BubbleButtonClickUpdateNotifier extends ChangeNotifier {
  void notifyBubbleButtonClickUpdateNotifier() {
    // If the updated path matches the current path, notify listeners
    notifyListeners();
  }
}


class DatabaseDataUpdatedNotifier extends ChangeNotifier {
  // Store the path of the UI component or screen
  late String currentPath;
  late String updatedPath;

  // This method will update the stored path and notify listeners
  void setPath(String path) {
    currentPath = path;
  }

  String getUpdatedPath() {
    return updatedPath;
  }

  // This method will notify listeners if the path matches the one being updated
  void notifyDatabaseDataUpdated(String gotUpdatedPath) {
    // If the updated path matches the current path, notify listeners
    updatedPath = gotUpdatedPath;
    if (updatedPath.contains(currentPath)) {
      notifyListeners();
    }
  }
}


class NotificationDatabaseChange extends ChangeNotifier {
  void notifyNotificationDatabaseChange() {
    notifyListeners();
  }
}


class NotificationPathNotifier extends ChangeNotifier {

  void notifyNotificationPathNotifier(){
    notifyListeners();
  }

}



class CheckConnectivityNotifier extends ChangeNotifier {
  void notifyCheckConnectivityNotifier() {
    notifyListeners();
  }
}

class ReconnectivityNotifier extends ChangeNotifier {
  void notifyReconnectivityNotifier() {
    // If the updated path matches the current path, notify listeners
    notifyListeners();
  }
}

