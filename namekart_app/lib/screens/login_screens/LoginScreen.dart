import 'dart:convert';
import 'dart:io';

import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:msal_auth/msal_auth.dart';
import 'package:namekart_app/activity_helpers/DbAccountHelper.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/MicrosoftLoginButton.dart';
import 'package:namekart_app/database/UserSettingsDatabase.dart';
import 'package:http/http.dart' as http;

import '../../activity_helpers/DbSqlHelper.dart';
import '../../activity_helpers/UIHelpers.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _signInAnonymously() async {

    await DbSqlHelper.initDatabase();
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      print("Signed in as: ${userCredential.user?.uid}");
    } catch (e) {
      print("Error during anonymous sign-in: $e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _signInAnonymously();
    if(!GlobalProviders.previouslyOpen) {
      _attemptAutoLogin(context);
      GlobalProviders.previouslyOpen=true;
    }
  }

  Future<void> _attemptAutoLogin(BuildContext context) async {
    final isDataPresent = await DbAccountHelper.isDataPresent("account~user~details");
    if (!isDataPresent) return;

    final msal= await SingleAccountPca.create(
      clientId: 'c671954e-7f6e-4db7-91f9-08fa9eca986b',
      androidConfig: Platform.isAndroid
          ? AndroidConfig(
        configFilePath: 'assets/msal_config_android.json',
        redirectUri: GlobalProviders().redirectUri,
      )
          : null,
      appleConfig: Platform.isIOS
          ? AppleConfig(
        authority: 'https://login.microsoftonline.com/eba2c098-631c-4978-8326-5d25c2d09ca5',
        authorityType: AuthorityType.aad,
        broker: Broker.msAuthenticator,
      )
          : null,
    );


    try {
      final result = await msal.acquireTokenSilent(scopes: ['User.Read']);

      GlobalProviders.userId = result.account.username!;
      GlobalProviders.loginToken = result.account;

      Navigator.pushReplacementNamed(context, 'home',
          arguments: {"isAdmin": true});
    } catch (e) {
      print("Silent token acquisition failed: $e");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/login_screen_images/loginpagenamekartlogo.png",
                  width: 170.sp,
                  height: 280.sp,
                ),
              ],
            ),
            text(
                text: "Welcome Back!",
                size: 17.sp,
                color: Color(0xff3F3F41),
                fontWeight: FontWeight.w400),
            MicrosoftLoginButton(),
          ]),
        ),
      ),
    );
  }
}