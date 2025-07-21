import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:namekart_app/activity_helpers/GlobalVariables.dart';

import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:namekart_app/cutsom_widget/AnimatedSlideTransition.dart';

import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../../change_notifiers/WebSocketService.dart';
import 'options_buttons/PersonalGroup/PersonalGroup.dart';
import 'options_buttons/UpdateVersions.dart';

class Options extends StatefulWidget {
  @override
  State<Options> createState() => _OptionsTabState();
}

class _OptionsTabState extends State<Options> {
  TextEditingController editingController = TextEditingController();
  bool bugReportButtonClicked = false;
  String foundBugText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF7F7F7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            IntrinsicHeight(
              child: AnimatedSlideTransition(
                animationType: BoxAnimationType.fadeInFromTop,
                duration: Duration(seconds: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20,left: 20,right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ScaleBigScreenTransition(
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,)
                                      ]),
                                  padding: EdgeInsets.all(10),
                                  child: Image.asset(
                                    "assets/images/home_screen_images/options_tab/personalgroup.png",
                                    width: 70,
                                    height: 70,
                                  )),
                              targetScreen:PersonalGroup(currentUserId: GlobalProviders.userId,),
                            ),
                          ),
                        ),
                    ),
                    Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(top: 20,left: 10,right: 20),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,)
                                  ]),
                              padding: EdgeInsets.all(10),
                              child: Image.asset(
                                "assets/images/home_screen_images/options_tab/quicknotes.png",
                                width: 70,
                                height: 70,
                              ))),
                    ),

                  ],
                ),
              ),
            ),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Expanded(
                    child: AnimatedSlideTransition(

                      animationType: BoxAnimationType.fadeInFromLeft,
                      duration: Duration(seconds: 1),
                      child: Padding(
                          padding: const EdgeInsets.only(top: 20,left: 20,right: 10),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,)
                                  ]),
                              padding: EdgeInsets.all(10),
                              child: Image.asset(
                                "assets/images/home_screen_images/options_tab/analytics.png",
                                width: 70,
                                height: 70,
                              ))),
                    ),
                  ),


                  Expanded(
                    child: AnimatedSlideTransition(
                      animationType: BoxAnimationType.fadeInFromRight,
                      duration: Duration(seconds: 1),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20,left: 10,right: 20),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  )
                              ]),
                          padding: EdgeInsets.all(10),
                          child: Image.asset(
                            "assets/images/home_screen_images/options_tab/hashtags.png",
                            width: 70,
                            height: 70,
                          ),
                        ),
                      ),
                    ),
                  ),



                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: AnimatedSlideTransition(

                      animationType: BoxAnimationType.fadeInFromLeft,
                      duration: Duration(seconds: 1),
                      child: Bounceable(
                        onTap: () {
                          _carouselCardsInfo("Found A Bug??",
                              "How does that bug occured ...", "bug-reports");
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20,left: 20,right: 10),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,)
                                ]),
                            padding: EdgeInsets.all(10),
                            child: Image.asset(
                              "assets/images/home_screen_images/options_tab/spottedsomethingswrong.png",
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: AnimatedSlideTransition(

                      animationType: BoxAnimationType.fadeInFromRight,
                      duration: Duration(seconds: 1),
                      child: Bounceable(
                        onTap: () {
                          _carouselCardsInfo(
                              "Have a Feature in Mind??",
                              "Describe your feature idea in detail to help us understand and develop it easily...",
                              "suggest-feature");
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20,left: 10,right: 20),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,)
                                ]),
                            padding: EdgeInsets.all(10),
                            child:  Image.asset(
                              "assets/images/home_screen_images/options_tab/havefeatureinmind.png",
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: AnimatedSlideTransition(

                      animationType: BoxAnimationType.fadeInFromBottom,
                      duration: Duration(seconds: 1),
                      child: Bounceable(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UpdateVersion()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20,left: 20,right: 10),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,)
                                ]),
                            padding: EdgeInsets.all(10),
                            child: Image.asset(
                              "assets/images/home_screen_images/options_tab/wehaveupgrade.png",
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Opacity(
                      opacity: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20,left: 10,right: 20),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,)
                              ]),
                          padding: EdgeInsets.all(10),
                          child:  Image.asset(
                            "assets/images/home_screen_images/options_tab/havefeatureinmind.png",
                            width: 70,
                            height: 70,
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
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
                              padding: const EdgeInsets.all(5),
                              child: TextField(
                                controller: editingController,
                                style: GoogleFonts.poppins(
                                  color: Color(0xff717171),
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
                                        TextStyle(color: Color(0xff717171))),
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
                                  const Duration(milliseconds: 40));

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
}
