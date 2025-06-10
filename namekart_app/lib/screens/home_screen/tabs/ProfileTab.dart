import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/change_notifiers/WebSocketService.dart';
import 'package:namekart_app/screens/home_screen/drawer/options/admin/AdminScreen.dart';
import 'package:namekart_app/screens/home_screen/drawer/options/settings/SettingsScreen.dart';
import '../../login_screens/LoginScreen.dart';

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        width: double.infinity,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.black12,
                    backgroundImage: AssetImage(
                      'assets/images/home_screen_images/appbar_images/profile.png',
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'John Doe',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'johndoe@example.com',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Admin Panel
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.black),
              title: Text(
                'Admin Panel',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return AdminScreen();
                    },
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
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

            // Settings
            ListTile(
              leading: Icon(Icons.settings),
              title: Text(
                'Settings',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return SettingsScreen();
                    },
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
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

            // Logout
            ListTile(
              leading: Icon(Icons.logout),
              title: Text(
                'Logout',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 350),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        LoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeIn,
                        ),
                        child: child,
                      );
                    },
                  ),
                      (Route<dynamic> route) => false,
                );
                WebSocketService().disconnect();
              },
            ),
          ],
        ),
      ),
    );
  }
}
