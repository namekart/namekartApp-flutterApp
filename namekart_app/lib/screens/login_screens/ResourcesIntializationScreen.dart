import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:namekart_app/screens/login_screens/LoginScreen.dart';
import 'package:path_provider/path_provider.dart';

class ResourcesIntializationScreen extends StatefulWidget{
  @override
  State<ResourcesIntializationScreen> createState() => _ResourcesIntializationScreenState();
}


class _ResourcesIntializationScreenState extends State<ResourcesIntializationScreen> {
  bool configured=false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    configureAllResources();
  }

  Future<void> configureAllResources() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File("${appDir.path}/storage.hive");
    print("Hive file size: ${await file.length()} bytes");
    await Hive.initFlutter(appDir.path);
    await Hive.openLazyBox('storage');
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) =>LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return
      Scaffold(
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
              SizedBox(height: 100,),
              const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    color: Colors.black12,
                    strokeWidth: 16,
                  )),
              SizedBox(height: 20,),
              text(text: "Getting all app resources...", size: 10, color: Color(0xff717171), fontWeight: FontWeight.w400)
            ]),
          ),
        ),
      );
  }
}

