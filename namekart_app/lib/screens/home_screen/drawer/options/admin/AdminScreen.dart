import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/screens/home_screen/drawer/options/admin/firestore_info/FirestoreInfo.dart';
import 'package:namekart_app/screens/home_screen/drawer/options/admin/user_account_details/UserAccountDetailsScreen.dart';

class AdminScreen extends StatefulWidget {
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.black,
        elevation: 5,
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
        actions: [
          Container(
            width: 2,
            height: 25.sp,
            color: Colors.black12,
          ),
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.admin_panel_settings)),
          Container(
            width: 60,
            height: 50,
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Color(0xff3DB070),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(100)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 5, bottom: 5),
              child: Text("Admin",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 8.sp,
                      color: Colors.white)),
            ),
          )
        ],
        actionsIconTheme: IconThemeData(color: Colors.white, size: 20),
        title: Row(
          children: [
            Text("Admin Panel",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Colors.white)),
          ],
        ),
        titleSpacing: 0,
        toolbarHeight: 50,
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF03A7FF), Color(0xFFAE002C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight))),
      ),
      body: Column(
        children: [
          Bounceable(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FirestoreInfo(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                                begin: Offset(1, 0), end: Offset(0, 0))
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 15),
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xffF5F5F5),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ]),
                child: Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Get Cloud\nFirestore\nDatabase\ninfo",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: Color(0xffB71C1C))),
                      Image.asset(
                        "assets/images/home_screen_images/drawer/options/admin/firestorelogo.png",
                        width: 150,
                        height: 150,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Bounceable(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      UserAccountDetailsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                                begin: Offset(1, 0), end: Offset(0, 0))
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xffF5F5F5),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ]),
                child: Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        "assets/images/home_screen_images/drawer/options/admin/accountdetails.png",
                        width: 100,
                        height: 150,
                      ),
                      Text("User Account\nDetails",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: Color(0xffB71C1C))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
