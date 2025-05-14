import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/change_notifiers/WebSocketService.dart';
import 'package:namekart_app/cutsom_widget/AnimatedAvatarIcon.dart';
import 'package:namekart_app/cutsom_widget/CustomShimmer.dart';
import 'package:namekart_app/cutsom_widget/SuperAnimatedWidget/SuperAnimatedWidget.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../activity_helpers/FirestoreHelper.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../database/NotificationDatabase.dart';
import '../../fcm/FcmHelper.dart';
import '../../activity_helpers/GlobalFunctions.dart';

class NotificationScreen extends StatefulWidget {
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  final GlobalKey<AnimatedListState> _listkey = GlobalKey<AnimatedListState>();
  late ScrollController _scrollController;

  late Future<List<Map<String, dynamic>>> data;
  List<Map<String, dynamic>> dataList = [];

  static bool databaseRefresh = false;

  late StreamSubscription<void> _notificationSubscription;
  late FCMHelper _fcmHelper;

  List<String> subCollections = [];
  Map<String, String> subCollectionsWithNotificationsCount = {};


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _scrollController = ScrollController();

    getSubCollections();

    _fcmHelper = FCMHelper();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationDatabaseChange =
      Provider.of<NotificationDatabaseChange>(context, listen: false);
      notificationDatabaseChange.addListener(getSubCollections);
    });
  }

  void getSubCollections() async {
    subCollections = await getSubCollectionNames("notifications");

    setState(() {
      for (String subCollection in subCollections) {
        int s = HiveHelper.getUnreadCountFlexible(
            "notifications~$subCollection");
        String subCollectionNotificationCount = s.toString();
        subCollectionsWithNotificationsCount.addAll(
            {subCollection: subCollectionNotificationCount});
      }
    });
  }


  void _showDraggableBottomSheet(BuildContext, String title,
      List<dynamic> responseList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full-screen expansion
      backgroundColor: Colors.transparent, // For rounded corners
      builder: (context) =>
          SuperAnimatedWidget(
            effects: [AnimationEffect.scale, AnimationEffect.fade],
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              // Start with 40% of the screen
              minChildSize: 0.4,
              // Minimum height
              maxChildSize: 1.0,
              // Maximum height (Full screen)
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          topLeft: Radius.circular(20))),
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                              topLeft: Radius.circular(20)),
                          color: Color(0xffB71C1C),
                        ),
                        child: Row(
                          children: [
                            Bounceable(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons
                                    .keyboard_backspace_rounded,
                                color: Colors.white, size: 20,),
                            ),
                            SizedBox(width: 10),
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                            controller: scrollController,
                            // Important for scrolling effect
                            itemCount: responseList.length,
                            itemBuilder: (context, index) =>
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Bounceable(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(context, PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                              secondaryAnimation) {
                                            return
                                              LiveDetailsScreen(
                                                mainCollection: "notifications",
                                                subCollection: title,
                                                subSubCollection: responseList[index]
                                                    .toString()
                                                    .trim(),
                                                showHighlightsButton: false,
                                                img: "assets/images/home_screen_images/appbar_images/notification.png",
                                              );
                                          }));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Color(0xfff2f2f2),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            right: 20),
                                        child:
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .start
                                          , children: [
                                          SizedBox(width: 15,),
                                          Container(
                                            width: 40,
                                            height: 40,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius
                                                  .circular(30),
                                              border: Border.all(
                                                  color: Colors.black12),
                                              color: Color(0xffD9D9D9),
                                            ),
                                            child: Text(responseList[index]
                                                .toString()
                                                .trim()[0],
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87),),
                                          ),
                                          SizedBox(width: 15,),
                                          Expanded(child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: 15, bottom: 15),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(responseList[index]
                                                    .toString()
                                                    .trim(),
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight
                                                          .bold,
                                                      color: Colors.black87),),
                                                SizedBox(height: 10,),
                                                Text("${HiveHelper
                                                    .getUnreadCountFlexible(
                                                    "notifications~$title~${responseList[index]
                                                        .toString()
                                                        .trim()}")} New Notification",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight
                                                          .bold,
                                                      color: ((HiveHelper
                                                          .getUnreadCountFlexible(
                                                          "notifications~$title~${responseList[index]
                                                              .toString()
                                                              .trim()}") == 0)
                                                          ? Colors.black45
                                                          : Color(0xff80B71C1C))

                                                  ),),
                                              ],
                                            ),
                                          )),
                                          Icon(Icons.navigate_next_rounded,
                                            color: Colors.black87, size: 20,)
                                        ],),
                                      ),

                                    ),
                                  ),
                                )
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _notificationSubscription.cancel();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    if (databaseRefresh) {
      print("object");
      databaseRefresh = false;
    }

    return Scaffold(
        backgroundColor: Colors.white,
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
                setState(() {});
              },
              icon: Image.asset(
                "assets/images/home_screen_images/appbar_images/notification.png",
                width: 20.sp,
                height: 20.sp,
              ),
            )
          ],
          actionsIconTheme: IconThemeData(color: Colors.white, size: 20),
          title: Row(
            children: [
              Text("Notifications",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: Colors.white)),
            ],
          ),
          titleSpacing: 0,
          toolbarHeight: 50,
          flexibleSpace: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF03A7FF), Color(0xFFAE002C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight))),
        ),
        body: Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: MediaQuery
                .of(context)
                .size
                .height,
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  children: [
                    GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                        ),
                        itemCount:
                        subCollectionsWithNotificationsCount
                            .length,
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        // Disable scrolling if inside another scrollable widget
                        itemBuilder: (context, index) {
                          return SuperAnimatedWidget(
                            effects: [
                              AnimationEffect.scale,
                              AnimationEffect.fade
                            ],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Bounceable(
                                // onTap: (){Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) {return NotificationDetailsScreen(tableName: subCollections[index], onBack: (){});}));},
                                onTap: () async {
                                  WebSocketService w = new WebSocketService();
                                  final reponse = await w
                                      .sendMessageGetResponse({
                                    "query": "firebase-subsubcollections",
                                    "path": "notifications.${subCollections[index]}"
                                  }, "user");
                                  final responseString = jsonDecode(
                                      reponse["data"])["response"]
                                      .toString()
                                      .substring(1,
                                      ((jsonDecode(reponse["data"])["response"])
                                          .length - 1));
                                  final List<
                                      dynamic> responseList = responseString
                                      .split(",");


                                  _showDraggableBottomSheet(
                                      context, subCollections[index],
                                      responseList);
                                },

                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Color(0xfff2f2f2),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child:
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center,
                                      crossAxisAlignment: CrossAxisAlignment
                                          .center
                                      , children: [
                                      AnimatedAvatarIcon(
                                        animationType: AnimationType.bounce,
                                        reverse: true,
                                        duration: Duration(seconds: 5),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                30),
                                            border: Border.all(
                                                color: Colors.black12),
                                            color: Color(0xffD9D9D9),
                                          ),
                                          child: Shimmer.fromColors(
                                              baseColor: Colors.black87,
                                              highlightColor: Colors.white,
                                              child: Text(
                                                subCollections[index][0],
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87),)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15, bottom: 15),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .center,
                                          mainAxisAlignment: MainAxisAlignment
                                              .center,
                                          children: [
                                            Shimmer.fromColors(

                                                baseColor: Colors.black87,
                                                highlightColor: Colors.white,
                                                child: Text(
                                                  subCollectionsWithNotificationsCount
                                                      .keys.elementAt(index),
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight
                                                          .bold,
                                                      color: Colors.black87),)),
                                            SizedBox(height: 10,),
                                            Text(
                                              "${subCollectionsWithNotificationsCount
                                                  .values.elementAt(
                                                  index)} New Notification",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: subCollectionsWithNotificationsCount
                                                      .values.elementAt(
                                                      index) == "0" ? Colors
                                                      .black45 : const Color(
                                                      0xff80B71C1C)
                                              ),),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.navigate_next_rounded,
                                        color: Colors.black87,)
                                    ],),
                                  ),

                                ),
                              ),
                            ),
                          );
                        }),
                    SizedBox(
                      height: 50,
                    )
                  ],
                ),
              ),
            )));
  }
}