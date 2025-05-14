import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/screens/home_screen/drawer/options/admin/AdminScreen.dart';
import 'package:namekart_app/screens/home_screen/drawer/options/settings/SettingsScreen.dart';

import '../../login_screens/LoginScreen.dart';

class Profiledrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75, // 75% screen width
      color: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            accountName: Text('John Doe',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black)),
            accountEmail: Text('johndoe@example.com',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.black)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.black12,
              backgroundImage: AssetImage(
                  'assets/images/home_screen_images/appbar_images/profile.png'),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.admin_panel_settings,
              color: Colors.black,
            ),
            horizontalTitleGap: 10,
            title: Text(
              'Admin Panel',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 500),
                  // Animation duration
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return AdminScreen();
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0); // Slide from right
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          ListTile(
            horizontalTitleGap: 10,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 500),
                  // Animation duration
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return SettingsScreen();
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0); // Slide from right
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            leading: Icon(Icons.settings),
            title: Text('Settings',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black)),
          ),
          ListTile(
            horizontalTitleGap: 10,
            leading: Icon(Icons.logout),
            title: Text('Logout',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LoginScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                          parent: animation, curve: Curves.easeIn),
                      child: child,
                    );
                  },
                  transitionDuration: Duration(milliseconds: 350),
                ),
                (Route<dynamic> route) => false, // Removes all previous routes
              );
            },
          ),
        ],
      ),
    );
  }
}
