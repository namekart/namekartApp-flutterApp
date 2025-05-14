import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:namekart_app/change_notifiers/ConnectivityService.dart';
import 'package:namekart_app/change_notifiers/WebSocketService.dart';
import 'package:namekart_app/cutsom_widget/AnimatedAvatarIcon.dart';
import 'package:namekart_app/cutsom_widget/CustomShimmer.dart';
import 'package:namekart_app/cutsom_widget/TypewriterText.dart';
import 'package:namekart_app/database/LiveAuctionsDatabase.dart';
import 'package:namekart_app/database/LiveAuctionsListDatabase.dart';
import 'package:namekart_app/database/NotificationDatabase.dart';
import 'package:namekart_app/screens/features/BiddingList.dart';
import 'package:namekart_app/screens/features/WatchList.dart';
import 'package:namekart_app/screens/home_screen/drawer/ProfileDrawer.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:namekart_app/screens/notifications_screen/NotificationScreen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../activity_helpers/GlobalFunctions.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../features/BulkBid.dart';
import '../features/BulkFetch.dart';
import '../search_screen/SearchScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String day = getTodaysDateTime()[0];
  String date = getTodaysDateTime()[1];
  int activeIndex = 0;

  @override
  void initState() {
    super.initState();

    connectToWebsocket();

  }

  void connectToWebsocket()async{
    await WebSocketService().connect(
      GlobalProviders.userId,
      Provider.of<LiveDatabaseChange>(context, listen: false),
      Provider.of<LiveListDatabaseChange>(context, listen: false),
      Provider.of<NotificationDatabaseChange>(context, listen: false),
      Provider.of<NewNotificationTableAddNotifier>(context, listen: false),
      Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false),
    );

    final Map<String, dynamic> response = await WebSocketService().sendMessageGetResponse({
      "query": "reconnection-check",
    }, "user");


    final  reconnected = response != null &&
        response.containsKey('data') &&
        jsonDecode(response['data'])['response'].toString().contains("reconnected");

    if (reconnected) {
      WebSocketService.isConnected = true;
    }

  }

  @override
  void dispose() {
    // Close the WebSocket connection when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white, // Soft off-white background
        body: SingleChildScrollView(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                _buildAppBar(),
            Column(children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 110.sp,
                      height: 110.sp,
                      child: Image.asset(
                        "assets/images/home_screen_images/newwelcome.png",
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    Container(
                      width: 140.sp,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.black45, width: 1))),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: StrokeText(
                              text: "$day",
                              textStyle: GoogleFonts.poppins()
                                  .copyWith(
                                  color: Colors.black, fontSize: 18.sp),
                              strokeColor: Colors.black,
                              strokeWidth: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            date,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 10.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 10,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CarouselSlider(
                    items: [
                      _carouselCards(
                          "Spotted something wrong?", "Tell us here!",
                          "assets/images/home_screen_images/foundabug.png",
                          Color(0xfff3f3f3), Colors.black),
                      _carouselCards(
                          "Have a Feature in Mind?", "Help Us Shape the App!",
                          "assets/images/home_screen_images/haveafeatureinmind.png",
                          Color(0xff3B3F4B), Colors.white),
                      _carouselCards(
                          "We’ve Upgraded!", "Find Out What’s Changed",
                          "assets/images/home_screen_images/weupgraded.png",
                          Color(0xffEFBF04), Colors.white),
                      _carouselCards(
                          "New Surprises Inside!", "Check Out What’s Happening",
                          "assets/images/home_screen_images/newsurprise.png",
                          Color(0xffEFBF04), Colors.white),
                    ],
                    options: CarouselOptions(
                      height: 140.sp,
                      viewportFraction: 1.0,
                      onPageChanged: (index, reason) {
                        setState(() {
                          activeIndex = index;
                        });
                      },
                      enlargeCenterPage: true,
                      autoPlay: true,
                      autoPlayInterval: Duration(seconds: 10),
                      autoPlayAnimationDuration: Duration(milliseconds: 800),
                      scrollPhysics: BouncingScrollPhysics(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: AnimatedSmoothIndicator(
                      activeIndex: activeIndex,
                      count: 4,
                      effect: const ExpandingDotsEffect(
                        dotWidth: 4,
                        dotHeight: 4,
                        activeDotColor: Color(0xFFB71C1C),
                        dotColor: Color(0xFFB71C1C),
                        expansionFactor: 5,
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 10.sp,
              ),
              Container(
                  width: 310.sp,
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Container(
                            width: 320.sp,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: GestureDetector(

                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                              secondaryAnimation) {
                                            return Search();
                                          },
                                          transitionsBuilder: (context,
                                              animation, secondaryAnimation,
                                              child) {
                                            const begin = Offset(0.0, 1.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOut;
                                            var tween = Tween(
                                                begin: begin, end: end).chain(
                                                CurveTween(curve: curve));
                                            var offsetAnimation = animation
                                                .drive(tween);
                                            return SlideTransition(
                                              position: offsetAnimation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },


                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: CustomShimmer.fromColors(
                                        baseColor: Color(0xFFB71C1C),
                                        highlightColor: Colors.white,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                20),
                                            color: Color(0xFFB71C1C),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(13),
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      left: 8.0),
                                                  child: Text("Search",
                                                      style: GoogleFonts
                                                          .poppins(
                                                        fontWeight: FontWeight
                                                            .bold,
                                                        color: Colors.white,
                                                        fontSize: 10.sp,
                                                      )),
                                                ),
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      right: 8.0),
                                                  child: Image.asset(
                                                    "assets/images/home_screen_images/searchwhite.png",
                                                    width: 15.sp,
                                                    height: 15.sp,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Image.asset(
                              "assets/images/home_screen_images/finding.png",
                              width: 70.sp,
                              height: 80.sp,
                            ),
                            Container(
                              width: 100.sp,
                              child: Text(
                                "Find what you need, faster!",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  // Make it extra bold
                                  color: Color(0xFFB71C1C),
                                  fontSize: 12.sp,
                                ),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 10,)
                      ],
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  height: 1,
                  color: Colors.black12,
                ),
              ),
              Container(
                width: 310.sp,
                decoration: BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 10.sp,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset(
                          "assets/images/home_screen_images/livetv.png",
                          width: 50.sp,
                          height: 50.sp,
                        ),
                        Shimmer.fromColors(
                          baseColor: Color(0xFFB71C1C),
                          highlightColor: Colors.white,
                          child: Text(
                            "Live Status",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB71C1C),
                              fontSize: 12.sp,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 30.sp,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _LiveStatusImage("dropcatch"),
                          _LiveStatusImage("dynadot"),
                          _LiveStatusImage("godaddy"),
                          _LiveStatusImage("namecheap"),
                          _LiveStatusImage("namesilo")
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  width: 260.sp,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20)),
                  ),
                  child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 300),
                            pageBuilder: (context, animation,
                                secondaryAnimation) =>
                                LiveDetailsScreen(
                                  img: "assets/images/bubbles_images/seeall.png",
                                  mainCollection: "live",
                                  subCollection: "all",
                                  subSubCollection: "auctions",
                                  showHighlightsButton: true,
                                ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
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
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 10, bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("See All",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB71C1C),
                                    fontSize: 12.sp,
                                  )),
                              AnimatedAvatarIcon(
                                animationType: AnimationType.vibrate,
                                reverse: true,
                                child: Image.asset(
                                  "assets/images/home_screen_images/next.png",
                                  width: 15.sp,
                                  height: 15.sp,
                                ),
                              ),
                            ],
                          )))),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  height: 1,
                  color: Colors.black12,
                ),
              ),
              Container(
                  width: 310.sp,
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20, left: 20, right: 20, bottom: 10),
                        child: Text(
                          "Auction Tools",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              color: Color(0XFFB71C1C),
                              fontSize: 12.sp),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(children: [
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => BiddingList()));
                                },
                                child:
                                _AuctionTools("biddinglist", "Bidding List")),
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => WatchList()));
                                },
                                child: _AuctionTools(
                                    "watchlist", "Watch List")),
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => BulkBid()));
                                },
                                child: _AuctionTools("bulkbid", "Bulk Bid")),
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => BulkFetch()));
                                },
                                child: _AuctionTools(
                                    "bulkfetch", "Bulk Fetch")),
                          ]),
                          Image.asset(
                            "assets/images/home_screen_images/laptop.png",
                            width: 120.sp,
                            height: 100.sp,
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      )
                    ],
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  height: 1,
                  color: Colors.black12,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomShimmer.fromColors(
                  baseColor: Colors.black,
                  highlightColor: Colors.white,
                  period: Duration(seconds: 2),
                  child: Container(
                      width: 310.sp,
                      height: 150.sp,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 1),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30.0, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    "Crafted By ",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB71C1C),
                                        fontSize: 12.sp),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .end,
                                      children: [
                                        Text(
                                          "Namekart",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xffFF0000),
                                              fontSize: 15.sp,
                                              shadows: [
                                                Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 5)
                                              ]),
                                        ),
                                        Text(
                                          "Noida,Delhi",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xffB71C1C),
                                              fontSize: 10.sp),
                                        ),
                                      ]),
                                ),
                              ],
                            ),
                            Image.asset(
                              "assets/images/home_screen_images/crafted.png",
                              width: 80.sp,
                              height: 80.sp,
                            )
                          ],
                        ),
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  height: 1,
                  color: Colors.black12,
                ),
              ),
            ]),
        ])),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset(
              "assets/images/applogo-transparent.png",
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 8),
            Shimmer.fromColors(
              baseColor: Color(0xFFFF0000),
              highlightColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TypewriterText(
                  text: "Namekart",
                  textStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF0000),
                  ),
                  restartDelay: Duration(seconds: 5),
                  reverse: true,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 50,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return NotificationScreen(); // Your destination screen
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0); // Slide from right
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var slideTween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(slideTween);

                    var scaleTween = Tween(begin: 0.9, end: 1.0);
                    var scaleAnimation = animation.drive(scaleTween);

                    return SlideTransition(
                        position: offsetAnimation,
                        child: ScaleTransition(
                            scale: scaleAnimation, child: child));
                  },
                ),
              );
            },
            child: Image.asset(
              "assets/images/home_screen_images/appbar_images/notification.png",
              width: 15,
              height: 15,
            ),
          ),
          GestureDetector(
            onTap: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "Dismiss",
                transitionDuration: Duration(milliseconds: 400),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                        child: Profiledrawer()), // Your custom right drawer
                  );
                },
                transitionBuilder: (context, animation, secondaryAnimation,
                    child) {
                  var slide = Tween<Offset>(
                    begin: Offset(1.0, 0.0), // Start off-screen right
                    end: Offset.zero, // Slide to center-right
                  ).animate(animation);

                  return SlideTransition(
                    position: slide,
                    child: child,
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 10),
              child: Image.asset(
                "assets/images/home_screen_images/appbar_images/profile.png",
                width: 35,
                height: 35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carouselCards(String title, String subTitle, String img,
      Color cardColor, Color textColor) {
    return Container(
      width: 310.sp,
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20.sp,
              ),
              Container(
                width: 140.sp,
                child: Text(title,
                    style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp)),
              ),
              SizedBox(
                height: 10.sp,
              ),
              Container(
                width: 150.sp,
                child: Text(
                    subTitle,
                    style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 8.sp)),
              )
            ],
          ),
          Image.asset(
            img,
            width: 70.sp,
            height: 70.sp,
          )
        ],
      ),
    );
  }

  Widget _LiveStatusImage(String image) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LiveDetailsScreen(
                  img: "assets/images/home_screen_images/livelogos/$image.png",
                  mainCollection: "live",
                  subCollection: image,
                  subSubCollection: "auctions",
                  showHighlightsButton: true,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation,
                child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                    parent: animation, curve: Curves.easeIn),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        width: 25.sp,
        height: 25.sp,
        child: Image.asset(
          "assets/images/home_screen_images/livelogos/$image.png",
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Widget _AuctionTools(String image, String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomShimmer.fromColors(
          baseColor: Color(0xFF800020),
          highlightColor: Colors.white,
          opacity: 0.6,
          child: Container(
            width: 120.sp,
            height: 40.sp,
            decoration: BoxDecoration(
              color: Color(0xFF800020),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Image.asset(
                      "assets/images/home_screen_images/features/$image.png",
                      width: 13.sp,
                      height: 13.sp),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
