import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namekart_app/activity_helpers/GlobalFunctions.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../../../activity_helpers/FirestoreHelper.dart';

class UserAccountDetailsScreen extends StatefulWidget {
  @override
  State<UserAccountDetailsScreen> createState() =>
      _UserAccountDetailsScreenState();
}

class _UserAccountDetailsScreenState extends State<UserAccountDetailsScreen> {
  TextEditingController _emailTextFieldController=TextEditingController();
  TextEditingController _passwordTextFieldController=TextEditingController();

  String email="",password="";
  bool isAdmin=false;

  @override
  void initState() {
    // TODO: implement initState
    _emailTextFieldController.addListener(_getEmail);
    _passwordTextFieldController.addListener(_getPassword);
  }

  void _getEmail(){
    setState(() {
      email=_emailTextFieldController.text.trim();
    });
  }

  void _getPassword(){
    setState(() {
      password=_passwordTextFieldController.text.trim();
      print(password);
    });
  }


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
        actions: [
          Container(
            width: 2,
            height: 25.sp,
            color: Colors.black12,
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  _emailTextFieldController.clear();
                  _passwordTextFieldController.clear();
                });
                showDialog(
                  context: context,
                  // Provide the context
                  builder: (BuildContext context) {
                    return StatefulBuilder(builder: (context, setState) {

                      return AlertDialog(
                          contentPadding: const EdgeInsets.all(0),
                          backgroundColor: Color(0xffF5F5F5),
                          content: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 270.sp,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppBar(
                                  title: Text(
                                    "Add account",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Color(0xffB71C1C),
                                  iconTheme: IconThemeData(
                                      size: 20, color: Colors.white),
                                  titleSpacing: 0,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20))),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 50.sp,
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: Colors.white),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                child: Expanded(
                                                  child: TextField(
                                                    controller: _emailTextFieldController,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black45,
                                                      fontSize: 12.sp,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                    decoration: InputDecoration(
                                                        labelText: 'Email',
                                                        border:
                                                            InputBorder.none,
                                                        labelStyle:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black45,
                                                          fontSize: 12.sp,
                                                          decoration:
                                                              TextDecoration
                                                                  .none,
                                                        ),
                                                        prefixIcon:
                                                            Icon(Icons.email),
                                                        prefixIconColor:
                                                            Color(0xffB71C1C)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        height: 50.sp,
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: Colors.white),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                child: Expanded(
                                                  child: TextField(
                                                    controller: _passwordTextFieldController,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black45,
                                                      fontSize: 12.sp,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                    obscureText: true,
                                                    decoration: InputDecoration(
                                                        labelText: 'Password',
                                                        border:
                                                            InputBorder.none,
                                                        labelStyle:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black45,
                                                          fontSize: 12.sp,
                                                          decoration:
                                                              TextDecoration
                                                                  .none,
                                                        ),
                                                        prefixIcon:
                                                            Icon(Icons.lock),
                                                        prefixIconColor:
                                                            Color(0xffB71C1C)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 5),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "Admin : ",
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  Transform.scale(
                                                    scale: 0.7, // Increase size (1.0 is default, adjust as needed)
                                                    child: Switch(
                                                      value: isAdmin,
                                                      trackOutlineWidth: WidgetStatePropertyAll(0),
                                                      activeColor: Colors.green,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          isAdmin = value;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Bounceable(
                                                onTap: (){
                                                  if(email=="" || password==""){
                                                    showTopSnackBar(Overlay.of(context),CustomSnackBar.error(message: "Please enter valid details"));
                                                  }else{
                                                    Navigator.pop(context);
                                                    addDataToFirestore("accounts", email, {"admin":isAdmin,"password":password});
                                                    showTopSnackBar(Overlay.of(context),CustomSnackBar.success(message: "Account added successfully"));
                                                  }
                                                },
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xffE7E7E7),
                                                    borderRadius:
                                                    BorderRadius.all(Radius.circular(20)),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 10,bottom: 10,left: 15,right: 15),
                                                    child: Text("Add User",
                                                        style: GoogleFonts.poppins(
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12)),
                                                  ),
                                                ),
                                              ),


                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ));
                    });
                  },
                );
              },
              icon: const Icon(
                Icons.add_circle,
              )),
          Container(
            width: 60,
            height: 50,
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
                color: Color(0xff3DB070),
                borderRadius:
                    BorderRadius.only(bottomLeft: Radius.circular(100))),
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
            Text("User Account Details",
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
    );
  }
}
