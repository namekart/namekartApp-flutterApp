import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../change_notifiers/WebSocketService.dart';
import '../carousel_options/whatnewupdate/UpdateVersions.dart';

class HelpDesk extends StatefulWidget {
  @override
  State<HelpDesk> createState() => _HelpDeskState();
}

class _HelpDeskState extends State<HelpDesk> {
  TextEditingController editingController = TextEditingController();
  bool bugReportButtonClicked = false;
  String foundBugText = "";

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: text(
            text: "HelpDesk",
            size: 12.sp,
            color: Color(0xff717171),
            fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Bounceable(
                onTap: () async {
                  _carouselCardsInfo("Found A Bug??",
                      "How does that bug occured ...", "bug-reports");
                },
                child: _carouselCards(
                    "Spotted something wrong?",
                    "Tell us here!",
                    "assets/images/home_screen_images/foundabug.png",
                    Colors.white,
                    Colors.black),
              ),
              Bounceable(
                onTap: () {
                  _carouselCardsInfo(
                      "Have a Feature in Mind??",
                      "Describe your feature idea in detail to help us understand and develop it easily...",
                      "suggest-feature");
                },
                child: _carouselCards(
                    "Have a Feature in Mind?",
                    "Help Us Shape the App!",
                    "assets/images/home_screen_images/haveafeatureinmind.png",
                    Colors.white,
                    Colors.black),
              ),
              Bounceable(
                onTap: () {
                  Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                    return UpdateVersion();
                  }));
                },
                child: _carouselCards(
                    "We’ve Upgraded!",
                    "Find Out What’s Changed",
                    "assets/images/home_screen_images/weupgraded.png",
                    Colors.white,
                    Colors.black),
              ),
              _carouselCards(
                  "New Surprises Inside!",
                  "Check Out What’s Happening",
                  "assets/images/home_screen_images/newsurprise.png",
                  Colors.white,
                  Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Future _carouselCardsInfo(
      String title, String subTitle, String websocketQuery) {
    setState(() {
      editingController.text = "";
      foundBugText = "";
      bugReportButtonClicked = false;
    });
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.9,
          maxChildSize: 1.0,
          expand: false,
          // For rounded corners
          builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) => SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                            color: Color(0xffB71C1C),
                          ),
                          child: Row(
                            children: [
                              Bounceable(
                                onTap: () => Navigator.pop(context),
                                child: Icon(
                                  Icons.keyboard_backspace_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 10),
                              text(
                                text: title,
                                size: 10,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 5)
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: editingController,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 10,
                                ),
                                maxLines: null,
                                // allows multiple lines
                                expands: true,
                                // fills the SizedBox vertically
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: subTitle,
                                    contentPadding: EdgeInsets.all(5),
                                    hintStyle:
                                        TextStyle(color: Colors.black54)),
                              ),
                            ),
                          ),
                        ),

                        Bounceable(
                          onTap: () async {
                            setModalState(() {
                              bugReportButtonClicked = true;
                            });
                            if (editingController.text.isEmpty) {
                              await Haptics.vibrate(HapticsType.error);
                              showTopSnackBar(
                                Overlay.of(context),
                                displayDuration: Duration(milliseconds: 100),
                                animationDuration: Duration(seconds: 1),
                                CustomSnackBar.error(
                                    message: "Bug Report Details Are Empty !"),
                              );
                            } else {
                              await Future.delayed(
                                  const Duration(milliseconds: 50));

                              WebSocketService w = WebSocketService();

                              w.sendMessage({
                                "query": websocketQuery.toString(),
                              });

                              // If response comes within 5 seconds
                              showTopSnackBar(
                                Overlay.of(context),
                                displayDuration: Duration(milliseconds: 100),
                                animationDuration: Duration(seconds: 1),
                                CustomSnackBar.success(
                                    message: "Send Bug Report Successfully"),
                              );
                            }

                            Navigator.pop(context);

                            setModalState(() {
                              bugReportButtonClicked = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 10,
                              decoration: BoxDecoration(
                                color: Color(0xFFB71C1C),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: !bugReportButtonClicked
                                    ? Text(
                                        "Report This",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              )),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
    );
  }

  Widget _carouselCards(String title, String subTitle, String img,
      Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 1, spreadRadius: 1)
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20.sp,
              ),
              text(
                  text: title,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                  size: 12.sp),
              SizedBox(
                height: 10.sp,
              ),
              Container(
                width: 150.sp,
                child: text(
                    text: subTitle,
                    color: textColor,
                    fontWeight: FontWeight.w300,
                    size: 7.sp),
              ),
              SizedBox(
                height: 20,
              )
            ],
          ),
          Image.asset(
            img,
            width: 40.sp,
            height: 40.sp,
          )
        ],
      ),
    );
  }
}
