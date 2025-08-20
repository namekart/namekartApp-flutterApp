import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:provider/provider.dart';
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

  bool _hasInternet = true;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (mounted && _hasInternet != isConnected) {
        setState(() => _hasInternet = isConnected);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // It's safer to check initial connectivity before starting the monitor
      Connectivity().checkConnectivity().then((results) {
        final isConnected = results.any((r) => r != ConnectivityResult.none);
        if (mounted) {
          setState(() => _hasInternet = isConnected);
        }
      });
      checkConnectivityNotifier = Provider.of<CheckConnectivityNotifier>(context, listen: false);
      _startWebSocketMonitor();
    });
  }

  void _startWebSocketMonitor() {
    _webSocketCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_isReconnecting || !_hasInternet) return;

      final completer = Completer<bool>();
      void listener() {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }

      checkConnectivityNotifier.addListener(listener);
      WebSocketService().sendMessage({"query": "check-connection"});

      try {
        await completer.future.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        if (mounted) {
          _attemptAutoReconnect();
        }
      } finally {
        checkConnectivityNotifier.removeListener(listener);
      }
    });
  }

  void _attemptAutoReconnect() async {
    // 🛡️ CRITICAL FIX: Immediately exit if we are already reconnecting OR have no internet.
    if (_isReconnecting || !_hasInternet) return;
    _isReconnecting = true;

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

      final completer = Completer<bool>();
      void reconnectionVerifyListener() {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }

      final reconnectivityNotifier = Provider.of<ReconnectivityNotifier>(context, listen: false);
      reconnectivityNotifier.addListener(reconnectionVerifyListener);
      WebSocketService().sendMessage({"query": "reconnection-check"});

      final success = await completer.future.timeout(const Duration(seconds: 3), onTimeout: () => false);
      reconnectivityNotifier.removeListener(reconnectionVerifyListener);

      if (success) {
        WebSocketService.isConnected = true;
        if (mounted) {
          widget.onReconnectSuccess();
        }
      }
    } catch (e) {
      debugPrint("Silent reconnect attempt failed: ${e.toString()}");
    } finally {
      _isReconnecting = false;
    }
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