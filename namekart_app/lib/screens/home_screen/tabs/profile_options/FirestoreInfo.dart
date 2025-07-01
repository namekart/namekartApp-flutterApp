import 'dart:convert';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../activity_helpers/FirestoreHelper.dart';
import '../../../../activity_helpers/GlobalFunctions.dart';
import '../../../../activity_helpers/GlobalVariables.dart';
import '../../../../activity_helpers/UIHelpers.dart';
import '../../../../cutsom_widget/AnimatedAvatarIcon.dart';
import '../../../../cutsom_widget/SuperAnimatedWidget.dart';


class FirestoreInfo extends StatefulWidget {
  @override
  State<FirestoreInfo> createState() => _FirestoreInfoState();
}

class _FirestoreInfoState extends State<FirestoreInfo> {
  List<String> liveCollections = [];
  List<String> notificationsMainCollections = [];

  var info;
  List<String> documentNames = [];
  List<String> selectedDocs = [];
  final valueListenable = ValueNotifier<String?>(null);
  String selectedCollectionPath = "";

  int? documentCount;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getFirestoreInfo();
  }

  void getFirestoreInfo() async {
    liveCollections = await getSubCollections("live");
    notificationsMainCollections = await getSubCollections("notifications");

    setState(() {});
  }

  void _showDraggableBottomSheet(BuildContext context, String mainType,
      String subType, List<dynamic> responseList) {
    int pressedIconIndex = 0;

    if(responseList.toString()!="[]") {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (context) =>
            SuperAnimatedWidget(
              effects: [AnimationEffect.scale, AnimationEffect.fade],
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.5,
                maxChildSize: 1.0,
                expand: false,
                builder: (context, scrollController) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width,
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
                                  Text(
                                    subType.capitalize(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tab Buttons Row with underline on selected item
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(responseList.length, (index) {
                                  var item = responseList[index];

                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: 1),
                                    child: MaterialButton(
                                      onPressed: () async {
                                        if (pressedIconIndex != index) {
                                          var newInfo = await getDocumentCount(
                                            "$mainType/$subType/${responseList[index]
                                                .toString()
                                                .trim()}",
                                          );

                                          setState(() {
                                            pressedIconIndex = index;
                                            documentCount=newInfo;
                                            valueListenable.value = null;

                                            if (getDocumentCount(responseList[index]) == 0) {
                                              showTopSnackBar(
                                                Overlay.of(context),
                                                CustomSnackBar.info(
                                                  message: "No Data Found",
                                                ),
                                              );
                                            }
                                          });
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            item.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: pressedIconIndex == index
                                                  ? Colors.black
                                                  : Colors.grey,
                                            ),
                                          ),
                                          SizedBox(
                                            height: 3,
                                          ),
                                          // Underline for selected item
                                          if (pressedIconIndex == index)
                                            Container(
                                              height: 2,
                                              width: 30,
                                              color:
                                              Colors.redAccent, // Underline color
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            Container(
                              height: 250.sp,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 20, right: 20, top: 10),
                                      child: Container(
                                        padding: EdgeInsets.all(15),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF3F3F3),
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 1),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Total Data Present",
                                              style: GoogleFonts.poppins(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              "$documentCount Documents",
                                              style: GoogleFonts.poppins(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff3DB070),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(
                                          left: 20, right: 20),
                                      child: Container(
                                        padding: EdgeInsets.all(15),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF3F3F3),
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 1),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Cost Of Handling Database",
                                              style: GoogleFonts.poppins(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              "Free Tier",
                                              style: GoogleFonts.poppins(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff3DB070),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(
                                          left: 10, right: 10),
                                      child: Container(
                                        padding: EdgeInsets.all(15),
                                        decoration: const BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Bounceable(
                                              onTap: () {
                                                showConfirmationDialog(
                                                    context: context,
                                                    title: 'Delete Confirmation',
                                                    content:
                                                    'Are you sure you want to delete this item?',
                                                    onConfirm: () async {
                                                      await deleteAllDocumentsInPath(
                                                          selectedCollectionPath);

                                                      Navigator.pop(context);
                                                    },

                                                    snackBarMessage: 'Deleted!');
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.deepOrange,
                                                  borderRadius: BorderRadius
                                                      .all(
                                                      Radius.circular(10)),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      10),
                                                  child: Text(
                                                      "Delete All Documents",
                                                      style: GoogleFonts
                                                          .poppins(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight
                                                              .bold,
                                                          fontSize: 8)),
                                                ),
                                              ),
                                            ),
                                            Bounceable(
                                              onTap: () {
                                                showConfirmationDialog(
                                                    context: context,
                                                    title: 'Delete Confirmation',
                                                    content:
                                                    'Are you sure you want to delete this item?',
                                                    onConfirm: () async {
                                                      await deleteCollection(
                                                          selectedCollectionPath);

                                                      Navigator.pop(context);
                                                    },
                                                    snackBarMessage: 'Deleted!');
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius
                                                      .all(
                                                      Radius.circular(10)),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      10),
                                                  child: Text("Delete Channel",
                                                      style: GoogleFonts
                                                          .poppins(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight
                                                              .bold,
                                                          fontSize: 8)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      );
    }else{
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.info(
          message: "No Data Found",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            icon: const Icon(Icons.insert_drive_file_outlined),
          ),
          Container(
            width: 60,
            height: 50,
            alignment: Alignment.centerRight,
            decoration: const BoxDecoration(
              color: Color(0xff3DB070),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(100)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 5, bottom: 5),
              child: Text(
                "Admin",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 8.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 20),
        title: Row(
          children: [
            Text(
              "Firestore Info",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Live",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: const Color(0xffB71C1C),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: liveCollections
                    .map((item) => Bounceable(
                          onTap: () async {

                            final responseList = await getSubSubCollectionsFromAllFile("live",item);

                            _showDraggableBottomSheet(
                                context, "live", item, responseList);
                          },
                          child: Container(
                            width: 80.sp,
                            height: 80.sp,
                            child: Column(
                              children: [
                                getIconForButton(item, 20),
                                SizedBox(height: 10),
                                Text(
                                  item,
                                  style: GoogleFonts.poppins(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
              Text(
                "Notifications",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: const Color(0xffB71C1C),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Wrap(
                children: notificationsMainCollections
                    .map((item) => Bounceable(
                          onTap: () async {
                            final responseList = await getSubSubCollectionsFromAllFile("notifications",item);

                            _showDraggableBottomSheet(
                                context, "notifications", item, responseList);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 13, right: 10, top: 10, bottom: 10),
                            child: Container(
                              width: 80.sp,
                              height: 100.sp,
                              child: Column(
                                children: [
                                  AnimatedAvatarIcon(
                                    animationType: AnimationType.bounce,
                                    reverse: true,
                                    duration: Duration(seconds: 5),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border:
                                            Border.all(color: Colors.black12),
                                        color: Color(0xffD9D9D9),
                                      ),
                                      child: Shimmer.fromColors(
                                          baseColor: Colors.black87,
                                          highlightColor: Colors.white,
                                          child: Text(
                                            item.isEmpty?"/":item[0],
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87),
                                          )),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextScroll(
                                    velocity: Velocity(
                                        pixelsPerSecond: Offset(10, 10)),
                                    delayBefore: Duration(seconds: 3),
                                    item,
                                    style: GoogleFonts.poppins(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              )
            ],
          ),
        ),
      ),
    );
  }


}
