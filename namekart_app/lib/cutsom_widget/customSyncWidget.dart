import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/safe_area_values.dart';
import '../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../change_notifiers/WebSocketService.dart';

class AlertWidget extends StatefulWidget {
  final String path;
  final Widget child;
  final VoidCallback onReconnectSuccess;

  const AlertWidget({
    Key? key,
    required this.path,
    required this.child,
    required this.onReconnectSuccess,
  }) : super(key: key);

  @override
  State<AlertWidget> createState() => _AlertWidgetState();
}

class _AlertWidgetState extends State<AlertWidget> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late Timer _webSocketCheckTimer;

  late CheckConnectivityNotifier checkConnectivityNotifier;
  AnimationController? _currentSnackBarController; // Renamed for clarity

  bool _hasInternet = true;
  bool _isReconnecting = false; // To prevent multiple reconnection attempts

  @override
  void initState() {
    super.initState();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
          final isConnected = results.any((r) => r != ConnectivityResult.none);
          if (mounted && _hasInternet != isConnected) {
            setState(() => _hasInternet = isConnected);
            _showConnectivitySnack(isConnected);
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkConnectivityNotifier = Provider.of<CheckConnectivityNotifier>(context, listen: false);
      _startWebSocketMonitor();
    });
  }

  void _startWebSocketMonitor() {
    // Ensure only one timer is active
    _webSocketCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_isReconnecting) return; // Don't check if already trying to reconnect

      bool responded = false;
      final completer = Completer<bool>();

      void listener() {
        if (!completer.isCompleted) {
          responded = true;
          completer.complete(true);
        }
      }

      checkConnectivityNotifier.addListener(listener);
      WebSocketService().sendMessage({"query": "check-connection"});

      try {
        await completer.future.timeout(const Duration(seconds: 2));
        // If we reach here, it means the listener was called within 2 seconds
        await _dismissCurrentSnackbar(); // Dismiss any "checking" or "reconnecting" snackbar
      } on TimeoutException {
        // No response within 2 seconds, attempt auto-reconnect
        if (mounted) {
          _attemptAutoReconnect();
        }
      } finally {
        checkConnectivityNotifier.removeListener(listener);
      }
    });
  }

  void _attemptAutoReconnect() async {
    if (_isReconnecting) return;
    _isReconnecting = true;

    await _dismissCurrentSnackbar(); // Dismiss any previous snackbar
    _showWebSocketSnack("Reconnecting...");

    final ws = WebSocketService();
    try {
      await ws.connect(
        GlobalProviders.userId,
        Provider.of<LiveDatabaseChange>(context, listen: false),
        Provider.of<ReconnectivityNotifier>(context, listen: false),
        Provider.of<NotificationDatabaseChange>(context, listen: false),
        Provider.of<CheckConnectivityNotifier>(context, listen: false),
        Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false),
        Provider.of<BubbleButtonClickUpdateNotifier>(context, listen: false),
        Provider.of<NotificationPathNotifier>(context, listen: false),
        Provider.of<SnackBarSuccessNotifier>(context, listen: false),
        Provider.of<SnackBarFailedNotifier>(context, listen: false),
        Provider.of<ShowDialogNotifier>(context, listen: false),
      ).timeout(const Duration(seconds: 5));

      // Connection successful, now verify with a message
      final completer = Completer<bool>();
      void reconnectionListener() {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }

      Provider.of<ReconnectivityNotifier>(context, listen: false).addListener(reconnectionListener);
      WebSocketService().sendMessage({"query": "reconnection-check"});

      final success = await completer.future.timeout(const Duration(seconds: 3), onTimeout: () => false);

      if (success) {
        WebSocketService.isConnected = true; // Update WebSocketService's internal state
        await _dismissCurrentSnackbar();
        widget.onReconnectSuccess();
      } else {
        await _dismissCurrentSnackbar();
        _showWebSocketSnack("Reconnect failed. Retrying...");
      }
    } on TimeoutException {
      await _dismissCurrentSnackbar();
      _showWebSocketSnack("Connection attempt timed out. Retrying...");
    } catch (e) {
      await _dismissCurrentSnackbar();
      _showWebSocketSnack("Reconnect error: ${e.toString()}. Retrying...");
    } finally {
      _isReconnecting = false;
      // Ensure listener is removed even if connection fails or times out
      try {
        Provider.of<ReconnectivityNotifier>(context, listen: false,).removeListener(() {}); // Placeholder, ensure actual listener is removed
      } catch (e) {
        // Listener might have already been removed by completer
      }
    }
  }

  Future<void> _showConnectivitySnack(bool connected) async {
    await _dismissCurrentSnackbar(); // Dismiss any existing snackbar first
    _showSnackBar(
      connected ? '✅ Internet reconnected' : '⚠️ No internet connection',
      connected ? Colors.green : Colors.orange,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    showTopSnackBar(
        snackBarPosition: SnackBarPosition.bottom,
        safeAreaValues: SafeAreaValues(minimum: const EdgeInsets.only(top: 80)),
        Overlay.of(context),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Text(
            message,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 10.sp,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        persistent: true,
        dismissType: DismissType.none,
        onAnimationControllerInit: (controller) {
          _currentSnackBarController = controller;
          // Optionally set _snackbarVisible = true here if needed,
          // but current design doesn't strictly rely on it for preventing multiples.
        },
        onDismissed: () {
          _currentSnackBarController = null;
          // _snackbarVisible = false; // If you use this flag
        }
    );
  }

  void _showWebSocketSnack(String message) {
    showTopSnackBar(
        snackBarPosition: SnackBarPosition.bottom,
        safeAreaValues: SafeAreaValues(minimum: const EdgeInsets.only(bottom: 30)),
        Overlay.of(context),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded( // Use Expanded to prevent overflow for long messages
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 10.sp,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        persistent: true,
        dismissType: DismissType.none,
        onAnimationControllerInit: (controller) {
          _currentSnackBarController = controller;
          // Optionally set _snackbarVisible = true here
        },
        onDismissed: () {
          _currentSnackBarController = null;
          // _snackbarVisible = false; // If you use this flag
        }
    );
  }

  Future<void> _dismissCurrentSnackbar() async {
    if (_currentSnackBarController != null && _currentSnackBarController!.status == AnimationStatus.completed) {
      await _currentSnackBarController!.reverse();
      _currentSnackBarController = null; // Clear the controller after dismissal
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _webSocketCheckTimer.cancel();
    _dismissCurrentSnackbar(); // Dismiss any snackbar on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}