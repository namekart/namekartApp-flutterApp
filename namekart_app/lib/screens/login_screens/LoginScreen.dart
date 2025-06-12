import 'dart:convert';

import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/MicrosoftSignInButton.dart';
import 'package:namekart_app/database/UserSettingsDatabase.dart';
import 'package:http/http.dart' as http;

import '../../activity_helpers/UIHelpers.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int activeIndex = 0;

  TextEditingController _textEditingController1 = TextEditingController();
  TextEditingController _textEditingController2 = TextEditingController();

  late final webSocketService;

  String username = "";
  String password = "";
  bool _isLoading = false; // ✅ Declare _isLoading

  Future<void> _signInAnonymously() async {
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

    _textEditingController1.addListener(_getUserId);

    _textEditingController2.addListener(_getPassword);
  }

  void _getUserId() {
    setState(() {
      username = _textEditingController1.text.trim(); // Get the user ID
    });
  }

  void _getPassword() {
    setState(() {
      password = _textEditingController2.text.trim();
    });
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _textEditingController2.dispose();
    _textEditingController1.dispose();
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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: text(
                  text: "Welcome Back",
                  size: 14.sp,
                  color: Color(0xff3F3F41),
                  fontWeight: FontWeight.w400),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 30, right: 30, bottom: 20, top: 20),
              child: Container(
                height: 50.sp,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 0.5,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 200.sp,
                        child: TextField(
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                            fontSize: 10.sp,
                            decoration: TextDecoration.none,
                          ),
                          controller: _textEditingController1,
                          decoration: InputDecoration(
                              labelText: 'User ID',
                              border: InputBorder.none,
                              labelStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.w300,
                                color: Color(0xff717171),
                                fontSize: 10.sp,
                                decoration: TextDecoration.none,
                              ),
                              prefixIcon: Icon(
                                Icons.perm_identity_rounded,
                                size: 18.sp,
                                color: Color(0xff717171),
                              ),
                              prefixIconColor: Color(0xff717171)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Container(
                height: 50.sp,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 0.5,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 200.sp,
                        child: TextField(
                          controller: _textEditingController2,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                            fontSize: 10.sp,
                            decoration: TextDecoration.none,
                          ),
                          obscureText: true,
                          decoration: InputDecoration(
                              labelText: 'Password',
                              border: InputBorder.none,
                              labelStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.w300,
                                color: Color(0xff717171),
                                fontSize: 10.sp,
                                decoration: TextDecoration.none,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                size: 18.sp,
                                color: Color(0xff717171),
                              ),
                              prefixIconColor: Color(0xff717171)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, right: 30),
                  child: text(
                      text: "Forgot Password?",
                      size: 10,
                      color: const Color(0xffFF6B6B),
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 45, left: 45, right: 45, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Bounceable(
                    onTap: () async {
                      if (username.isEmpty || password.isEmpty) {
                        Haptics.vibrate(HapticsType.error);
                        _showSnackBar("❌ Please Enter UserId/Password");
                        return;
                      }

                      setState(() => _isLoading = true); // Start loading

                      try {
                        final response = await http.post(
                          Uri.parse(
                              "https://nk-phone-app-helper-microservice.politesky-7d4012d0.westus.azurecontainerapps.io/auth/login"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode(
                              {"username": username, "password": password}),
                        );

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          final isAdmin = data["admin"];

                          _showSnackBar("✅ Logged in successfully",
                              success: true);

                          UserSettingsDatabase userSettingsDatabase =
                              UserSettingsDatabase.instance;

                          userSettingsDatabase.addOrUpdateUser(
                              username, password);

                          GlobalProviders.userId = username;

                          await Future.delayed(Duration(seconds: 2));

                          Navigator.pushReplacementNamed(context, 'home',
                              arguments: {"isAdmin": isAdmin});

                          Haptics.vibrate(HapticsType.success);
                        } else {
                          _showSnackBar("❌ Wrong Username/Password");
                          Haptics.vibrate(HapticsType.error);
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        _showSnackBar("❌ Server error, please try again later");
                        Haptics.vibrate(HapticsType.error);
                        print(e);
                      }
                      setState(() => _isLoading = false); // Stop loading
                    },
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: Color(0xffE63946),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 5,
                                  ))
                              : text(
                                  text: "Login",
                                  size: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  // MicrosoftSignInButton()
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                text(
                    text: "Don’t have an account? ",
                    size: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w300),
                text(
                    text: "Register Now ",
                    size: 10,
                    color: Color(0xffFF6B6B),
                    fontWeight: FontWeight.w300),
              ],
            )
          ]),
        ),
      ),
    );
  }
}
