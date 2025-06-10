import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/change_notifiers/AllDatabaseChangeNotifiers.dart';
import 'package:namekart_app/fcm/FcmHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/screens/home_screen/HomeScreen.dart';
import 'package:namekart_app/screens/login_screens/LoginScreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'change_notifiers/WebSocketService.dart';
import 'cutsom_widget/customSyncWidget.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMHelper().initializeFCM();

  final appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);

  // Open the storage box
  await Hive.openBox('storage');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WebSocketService()),
        ChangeNotifierProvider(create: (context) => LiveDatabaseChange()),
        ChangeNotifierProvider(create: (context) => LiveListDatabaseChange()),
        ChangeNotifierProvider(create: (context) => NotificationDatabaseChange()),
        ChangeNotifierProvider(create: (context) => NewNotificationTableAddNotifier()),
        ChangeNotifierProvider(create: (context) => DatabaseDataUpdatedNotifier()),
        ChangeNotifierProvider(create: (context) => RebuildNotifier()),
        ChangeNotifierProvider(create: (context) => NotifyRebuildChange()),
      ],
      child: MyApp(),
    ),
  );
}


class MyHttpOverrides extends HttpOverrides {

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {


  @override
  Widget build(BuildContext context) {


    GlobalProviders.initialize(context);

    WebSocketService.onBroadcastMessage.listen((onData){
      print("ondata $onData");
    });
    return AlertWidget(
      onReconnectSuccess:(){},
      path: '',
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          initialRoute: '/',
          routes: {
            'home': (context) => HomeScreen(),
          },
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),
        ),
      ),
    );
  }
}