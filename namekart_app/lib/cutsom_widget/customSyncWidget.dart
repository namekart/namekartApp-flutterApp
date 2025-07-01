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
  AnimationController? topSnackBarController;

  bool _hasInternet = true;
  bool _timerInitialized = false;
  bool _snackbarVisible = false;

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
    _webSocketCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      bool responded = false;

      void listener() {
        responded = true;
        checkConnectivityNotifier.removeListener(listener);
        _dismissSnackbar();
      }

      checkConnectivityNotifier.addListener(listener);
      WebSocketService().sendMessage({"query": "check-connection"});

      await Future.delayed(const Duration(seconds: 10));
      checkConnectivityNotifier.removeListener(listener);

      if (!responded) {
        _attemptAutoReconnect();
      }
    });
  }

  void _attemptAutoReconnect() async {
    if (_snackbarVisible) return;
    _showWebSocketSnack("Reconnecting...");

    try {
      final ws = WebSocketService();
      await ws.connect(
        GlobalProviders.userId,
        Provider.of<LiveDatabaseChange>(context, listen: false),
        Provider.of<ReconnectivityNotifier>(context, listen: false),
        Provider.of<NotificationDatabaseChange>(context, listen: false),
        Provider.of<CheckConnectivityNotifier>(context, listen: false),
        Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false),
        Provider.of<BubbleButtonClickUpdateNotifier>(context, listen: false),
        Provider.of<NotificationPathNotifier>(context, listen: false),
      ).timeout(const Duration(seconds: 5));

      bool success = false;
      void reconnectionListener() {
        success = true;
        Provider.of<ReconnectivityNotifier>(context, listen: false)
            .removeListener(reconnectionListener);
      }

      Provider.of<ReconnectivityNotifier>(context, listen: false)
          .addListener(reconnectionListener);

      WebSocketService().sendMessage({"query": "reconnection-check"});
      await Future.delayed(const Duration(seconds: 3));

      if (success) {
        WebSocketService.isConnected = true;
        _dismissSnackbar();
        widget.onReconnectSuccess();
      } else {
        _showWebSocketSnack("Reconnect failed. Retrying...");
      }
    } catch (_) {
      _showWebSocketSnack("Reconnect error. Retrying...");
    }
  }

  void _showConnectivitySnack(bool connected) {
    _showSnackBar(
      connected ? '✅ Internet reconnected' : '⚠️ No internet connection',
      connected ? Colors.green : Colors.orange,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (_snackbarVisible) return;

    _snackbarVisible = true;
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
        topSnackBarController = controller;
      },
    );
  }

  void _showWebSocketSnack(String message) {
    _snackbarVisible = true;
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
            Text(
              message,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 10.sp,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
      persistent: true,
      dismissType: DismissType.none,
      onAnimationControllerInit: (controller) {
        topSnackBarController = controller;
      },
    );
  }

  Future<void> _dismissSnackbar() async {
    if (topSnackBarController != null && topSnackBarController!.isCompleted) {
      await topSnackBarController!.reverse();
    }
    _snackbarVisible = false;
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _webSocketCheckTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
