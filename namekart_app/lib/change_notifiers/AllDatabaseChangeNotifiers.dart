import 'package:flutter/cupertino.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';

import '../main.dart';

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

  late String pathOfUpdatedDocument;

  // This method will update the stored path and notify listeners
  void setPath(String path) {
    currentPath = path;
  }

  String getUpdatedPath() {
    return updatedPath;
  }


  void setPathOfUpdatedDocument(String path){
    pathOfUpdatedDocument=path;
  }

  String getPathOfUpdatedDocument(){
    return pathOfUpdatedDocument;
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


class CurrentDateChangeNotifier extends ChangeNotifier {
  String currentDate='';
  void setCurrentDate(String currentDate) {
    currentDate = currentDate;
  }

  String getCurrentDate() {
    return currentDate;
  }

  void notifyCurrentDateChangeNotifier() {
    // If the updated path matches the current path, notify listeners
    notifyListeners();
  }
}


class SnackBarSuccessNotifier extends ChangeNotifier {
  void notifySnackBarSuccessNotifier(String message) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showTopSnackbar(message, true);

    }
  }
}

class SnackBarFailedNotifier extends ChangeNotifier {
  void notifySnackBarFailedNotifier(String message) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showCustomDialog(ctx,"Failed",message);
    }
  }
}

  class ShowDialogNotifier extends ChangeNotifier {
  void notifyShowDialogNotifier() {
    notifyListeners();
  }
}

