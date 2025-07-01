import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:namekart_app/activity_helpers/GlobalVariables.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';

import 'package:namekart_app/screens/home_screen/tabs/profile_options/FirestoreInfo.dart';
import 'package:namekart_app/screens/home_screen/tabs/profile_options/NotificationsScreen.dart';
import 'package:namekart_app/screens/home_screen/tabs/profile_options/SettingsScreen.dart';
import '../../login_screens/LoginScreen.dart';

class ProfileTab extends StatelessWidget {
  String? userName=GlobalProviders.loginToken.name;
  String? userEmail=GlobalProviders.loginToken.username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xffF7F7F7),
        width: double.infinity,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xffFFFFFF),
                border: Border.all(color: Colors.black12, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(border: Border.all(width: 2,color: Colors.black12),shape: BoxShape.circle),
                            child: text(text: userName.toString()[0], size: 12.sp, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          text(
                              text: GlobalProviders.loginToken.name!,
                              size: 12,
                              fontWeight: FontWeight.w300,
                              color: Color(0xff717171)),
                          text(
                              text: userEmail!,
                              size: 10,
                              fontWeight: FontWeight.w300,
                              color: Color(0xffA8A7A7)),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    // Admin Panel

                    Container(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.black12, width: 1))),
                      child: ListTile(
                        titleAlignment: ListTileTitleAlignment.center,
                        leading: Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xffA8A7A7),
                          size: 20,
                        ),
                        title: text(
                          text: 'Firestore Info',
                          size: 12,
                          fontWeight: FontWeight.w300,
                          color: Color(0xffA8A7A7),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 500),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return FirestoreInfo();
                              },
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                var tween = Tween(
                                  begin: Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeInOut));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.black12, width: 1))),
                      child: ListTile(
                        titleAlignment: ListTileTitleAlignment.center,
                        leading: Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xffA8A7A7),
                          size: 20,
                        ),
                        title: text(
                          text: 'Notifications',
                          size: 12,
                          fontWeight: FontWeight.w300,
                          color: Color(0xffA8A7A7),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 500),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return NotificationsScreen();
                              },
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                var tween = Tween(
                                  begin: Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeInOut));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.black12, width: 1))),
                      child: ListTile(
                        titleAlignment: ListTileTitleAlignment.center,
                        leading: Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xffA8A7A7),
                          size: 20,
                        ),
                        title: text(
                          text: 'Settings',
                          size: 12,
                          fontWeight: FontWeight.w300,
                          color: Color(0xffA8A7A7),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 500),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return SettingsScreen();
                              },
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                var tween = Tween(
                                  begin: Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeInOut));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    ListTile(
                      titleAlignment: ListTileTitleAlignment.center,
                      leading: Icon(
                        Icons.admin_panel_settings,
                        color: Color(0xffA8A7A7),
                        size: 20,
                      ),
                      title: text(
                        text: 'Logout',
                        size: 12,
                        fontWeight: FontWeight.w300,
                        color: Color(0xffA8A7A7),
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 500),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                              return LoginScreen();
                            },
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              var tween = Tween(
                                begin: Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeInOut));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),

                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
