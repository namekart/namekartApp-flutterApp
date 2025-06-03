import 'dart:convert';

import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/database/UserSettingsDatabase.dart';
import 'package:http/http.dart' as http;

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
  bool _isLoading = false;  // ✅ Declare _isLoading


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
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(children: [
            PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight),
                child: AppBar(
                  backgroundColor: Colors.white,
                  title: Row(
                    children: [
                      Image.asset(
                        "assets/images/applogo-transparent.png",
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          "Namekart",
                          style: GoogleFonts.poppins(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF0000),
                          ),
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  toolbarHeight: 50,
                )),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 320.sp,
              height: 90.sp,
              decoration: BoxDecoration(
                color: Color(0xffB71C1C),
                borderRadius: BorderRadius.all(Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Image.asset(
                    "assets/images/login_screen_images/login.png",
                    width: 50.sp,
                    height: 50.sp,
                  ),
                  Text(
                    "Login",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 15.sp,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
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
                        color: Colors.black26,
                        blurRadius: 10,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20),
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
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 10.sp,
                            decoration: TextDecoration.none,
                          ),
                          controller: _textEditingController1,
                          decoration: InputDecoration(
                              labelText: 'Username',
                              border: InputBorder.none,
                              labelStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB71C1C),
                                fontSize: 10.sp,
                                decoration: TextDecoration.none,
                              ),
                              prefixIcon: Icon(Icons.email,size: 18,),
                              prefixIconColor: Color(0xffB71C1C)),
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
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20),
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
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 10.sp,
                            decoration: TextDecoration.none,
                          ),
                          obscureText: true,
                          decoration: InputDecoration(
                              labelText: 'Password',
                              border: InputBorder.none,
                              labelStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Color(0xffB71C1C),
                                fontSize: 10.sp,
                                decoration: TextDecoration.none,
                              ),
                              prefixIcon: Icon(Icons.lock,size: 18,),
                              prefixIconColor: Color(0xffB71C1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: SizedBox(
                    width: 50,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child:  GestureDetector(
                    onTap: () async {
                      if (username.isEmpty || password.isEmpty) {
                        _showSnackBar("❌ Please Enter UserId/Password");
                        Haptics.vibrate(HapticsType.error);
                        return;
                      }

                      setState(() => _isLoading = true); // Start loading

                      try {
                        final response = await http.post(
                          Uri.parse("http://192.168.1.6:8081/auth/login"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({"username": username, "password": password}),
                        );

                        setState(() => _isLoading = false); // Stop loading

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          final isAdmin = data["admin"];

                          _showSnackBar("✅ Logged in successfully", success: true);

                          UserSettingsDatabase userSettingsDatabase = UserSettingsDatabase.instance;

                          userSettingsDatabase.addOrUpdateUser(username, password);

                          GlobalProviders.userId = username;


                          Future.delayed(Duration(seconds: 1), () {
                            Navigator.pushReplacementNamed(context, 'home',
                                arguments: {"isAdmin": isAdmin});

                            Haptics.vibrate(HapticsType.error);

                          });
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
                    },
                    child: Container(
                      width: 80.sp,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 5,
                          ),
                        ],
                        color: Color(0xFFFF0000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _isLoading
                              ? SizedBox(height:20,width: 20,child: CircularProgressIndicator(color: Colors.white,strokeWidth: 5,)) // ✅ Show Loader
                              : Text(
                            "Login",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            CarouselSlider(
              items: [
                Container(
                  width: 320.sp,
                  decoration: BoxDecoration(
                    color: Color(0xffF6F6F6),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 160.sp,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 20.sp,
                            ),
                            Container(
                              width: 170.sp,
                              child: Text("Discover Premium Domains",
                                  style: GoogleFonts.poppins(
                                      color: Color(0xFFB71C1C),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.sp)),
                            ),
                            SizedBox(
                              height: 15.sp,
                            ),
                            Container(
                              width: 170.sp,
                              child: Text(
                                  "Find the perfect name for your business – trusted by startups worldwide!",
                                  style: GoogleFonts.poppins(
                                      color: Colors.black38,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 8.sp)),
                            )
                          ],
                        ),
                      ),
                      Image.asset(
                        "assets/images/login_screen_images/discoverpremiumdomains.png",
                        width: 70.sp,
                        height: 70.sp,
                      )
                    ],
                  ),
                ),
                Container(
                  width: 320.sp,
                  decoration: const BoxDecoration(
                    color: Color(0xffF6F6F6),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 160.sp,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 20.sp,
                            ),
                            Container(
                              width: 170.sp,
                              child: Text("Secure Your\nBrand",
                                  style: GoogleFonts.poppins(
                                      color: Color(0xFFB71C1C),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.sp)),
                            ),
                            SizedBox(
                              height: 15.sp,
                            ),
                            Container(
                              width: 170.sp,
                              child: Text(
                                  "Stealth acquisitions and expert valuations to help you stand out.",
                                  style: GoogleFonts.poppins(
                                      color: Colors.black38,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 8.sp)),
                            )
                          ],
                        ),
                      ),
                      Image.asset(
                        "assets/images/login_screen_images/secureyourbrand.png",
                        width: 70.sp,
                        height: 70.sp,
                      )
                    ],
                  ),
                ),
                Container(
                  width: 320.sp,
                  decoration: BoxDecoration(
                    color: Color(0xffF6F6F6),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 160.sp,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 20.sp,
                            ),
                            Container(
                              width: 170.sp,
                              child: Text("Your Success, Our Priority",
                                  style: GoogleFonts.poppins(
                                      color: Color(0xFFB71C1C),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.sp)),
                            ),
                            SizedBox(
                              height: 15.sp,
                            ),
                            Container(
                              width: 170.sp,
                              child: Text(
                                  "With a 90% success rate, Namekart ensures you get what you need.",
                                  style: GoogleFonts.poppins(
                                      color: Colors.black38,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 8.sp)),
                            )
                          ],
                        ),
                      ),
                      Image.asset(
                        "assets/images/login_screen_images/yoursuccessispriority.png",
                        width: 70.sp,
                        height: 70.sp,
                      )
                    ],
                  ),
                ),
              ],
              options: CarouselOptions(
                clipBehavior: Clip.none,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    activeIndex = index;
                  });
                },
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 10),
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                scrollPhysics: BouncingScrollPhysics(),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
