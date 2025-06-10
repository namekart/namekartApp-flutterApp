import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/safe_area_values.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
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
  bool _hasInternet = true;

  bool reconnecting = false;

  AnimationController? topSnackBarController;

  late Timer _webSocketCheckTimer;

  bool snackbarShowing=false;

  late var connected;

  bool _timerInitialized = false;



  @override
  void initState() {
    super.initState();

    if (!_timerInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkConnectivity();

        _connectivitySubscription = Connectivity()
            .onConnectivityChanged
            .listen((List<ConnectivityResult> results) {
          final connected = results.any((r) => r != ConnectivityResult.none);
          if (mounted && _hasInternet != connected) {
            setState(() {
              _hasInternet = connected;
            });
            _showConnectivitySnack();
          }
        });

        _webSocketCheckTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
          if (!mounted) {
            timer.cancel();
            return;
          }

          try {
            final ws = WebSocketService();

            final response = await ws.sendMessageGetResponse({
              "query": "check-connection",
            }, "user").timeout(
              const Duration(seconds: 20),
              onTimeout: () => <String, dynamic>{},
            );

            final stillConnected = response.isNotEmpty &&
                response.containsKey('data') &&
                jsonDecode(response['data'])['response']
                    .toString()
                    .toLowerCase()
                    .contains("connected");

            if (stillConnected) {
              // If already connected, dismiss any warning
              if (snackbarShowing) {
                await _dismissSnackbar();
              }
            } else {
              // Show warning only if connection check failed after timeout
              if (!snackbarShowing) {
                await _dismissSnackbar();
                _showWebSocketSnack();
              }
            }
          } catch (e) {
            // In case of exceptions, treat as disconnected
            if (!snackbarShowing) {
              await _dismissSnackbar();
              _showWebSocketSnack();
            }
          }
        });


        _timerInitialized = true;
      });
    }
  }

  void _checkConnectivity() async {
    var results = await Connectivity().checkConnectivity();
    final connected = results.any((r) => r != ConnectivityResult.none);
    if (mounted && _hasInternet != connected) {
      setState(() {
        _hasInternet = connected;
      });
      _showConnectivitySnack();
    }
  }

  Future<void> _showConnectivitySnack() async {
    final isConnected = _hasInternet;
    final message = isConnected ? '✅ Internet reconnected' : '⚠️ No internet connection';
    final color = isConnected ? Colors.green : Colors.orange;

    if (isConnected) {
      await _dismissSnackbar(); // Dismiss on reconnection
    } else {
      _showSnackBar(message, color);
    }
  }


  void _showWebSocketSnack() {
    snackbarShowing=true;
    showTopSnackBar(
      snackBarPosition: SnackBarPosition.bottom,
      safeAreaValues: SafeAreaValues(minimum: EdgeInsets.only(bottom: 30)),
      Overlay.of(context),
      Container(
        decoration: BoxDecoration(
          color: Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "❌ WebSocket disconnected",
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
            Bounceable(
              onTap: () async {

                if(reconnecting=false) {
                  _dismissSnackbar();
                  await Future.delayed(Duration(milliseconds: 100));
                  _showWebSocketSnack(); // show again with loading
                }
                setState(() {
                  reconnecting = true;
                });

                try {
                  final ws = WebSocketService();
                  await ws.connect(
                    GlobalProviders.userId,
                    Provider.of<LiveDatabaseChange>(context, listen: false),
                    Provider.of<LiveListDatabaseChange>(context, listen: false),
                    Provider.of<NotificationDatabaseChange>(context, listen: false),
                    Provider.of<NewNotificationTableAddNotifier>(context, listen: false),
                    Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false),
                    Provider.of<NotifyRebuildChange>(context, listen: false),
                  ).timeout(const Duration(seconds: 5), onTimeout: () {
                    throw TimeoutException("WebSocket connection timed out");
                  });

                  // Wait up to 2 seconds for reconnection verification
                  final responseFuture = ws.sendMessageGetResponse({
                    "query": "reconnection-check",
                  }, "user");

                  final response = await responseFuture.timeout(
                    const Duration(seconds: 2),
                    onTimeout: () =>  <String, dynamic>{},
                  );

                  final reconnected = response != null &&
                      response.containsKey('data') &&
                      jsonDecode(response['data'])['response'].toString().contains("reconnected");

                  if (reconnected) {
                    WebSocketService.isConnected = true;
                    widget.onReconnectSuccess(); // fire success callback
                    _dismissSnackbar(); // remove snackbar
                  } else {
                    setState(() {
                      reconnecting = false;
                      _dismissSnackbar();
                      _showWebSocketSnack();

                    });
                  }
                } catch (e) {
                  setState(() {
                    reconnecting = false;
                    _dismissSnackbar();
                    _showWebSocketSnack();
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: reconnecting ? Colors.transparent : Color(0xFF3DB070),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!reconnecting)
                        Text(
                          "Reconnect",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 10.sp,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      if (reconnecting)
                        const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 12,
                            )),
                    ],
                  ),
                ),
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
    try {
      if (topSnackBarController != null && topSnackBarController!.isCompleted) {
        await topSnackBarController!.reverse();
      }
    } catch (_) {}

    topSnackBarController = null;
    snackbarShowing = false;
    reconnecting = false;
  }



  void _showSnackBar(String message, Color backgroundColor) {
    if (snackbarShowing) return; // Prevent multiple snackbars
    snackbarShowing = true;

    showTopSnackBar(
      snackBarPosition: SnackBarPosition.bottom,
      safeAreaValues: SafeAreaValues(minimum: EdgeInsets.only(top: 80)),
      Overlay.of(context),
      Container(
        decoration: BoxDecoration(
          color: Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
      ),
      persistent: true,
      dismissType: DismissType.none,
      onAnimationControllerInit: (controller) {
        topSnackBarController = controller;
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _webSocketCheckTimer.cancel(); // prevent memory leaks

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}