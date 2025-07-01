import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
class UpdateVersion extends StatefulWidget{
  @override
  State<UpdateVersion> createState() => _UpdateVersionState();
}

class _UpdateVersionState extends State<UpdateVersion> {

  @override
  Widget build(BuildContext context) {

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
            onPressed: () {},
            icon: const Icon(Icons.system_security_update),
          ),
        ],
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 20),
        title: Row(
          children: [
            Text(
              "Update Versions",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        toolbarHeight: 50,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF03A7FF), Color(0xFFAE002C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20,),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.all(Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12,blurRadius: 5)]
              ),
              padding: EdgeInsets.only(top: 10,left: 20,right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Version 1 Beta",style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffB71C1C),
                      ),),
                      SizedBox(width: 20,),
                      Image.asset('assets/images/home_screen_images/carousel_options/whatnewupdate/appstorelogo.png',width: 15,height: 15,),
                      SizedBox(width: 10,),
                      Image.asset('assets/images/home_screen_images/carousel_options/whatnewupdate/googleplaylogo.png',width: 15,height: 15,)
                    ],
                  ),
                  SizedBox(width: 20,),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text("-> Added New Bubble Window",style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),),
                  )
                ],
              ),

            ),
          ),

        ],
      ),
    );
  }
}