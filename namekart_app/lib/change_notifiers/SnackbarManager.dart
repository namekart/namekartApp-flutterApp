import 'package:flutter/material.dart';

class SnackbarManager with ChangeNotifier {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void showSnackbar(BuildContext context, String message, {SnackBarAction? action}) {
    if (scaffoldMessengerKey.currentState != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
        ),
      );
    }
  }

  void showConnectivitySnackbar(BuildContext context, bool isConnected) {
    String message = isConnected ? 'Internet connection restored!' : 'No internet connection!';
    showSnackbar(context, message);
  }
}

