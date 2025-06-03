import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/change_notifiers/WebSocketService.dart';
import 'package:namekart_app/cutsom_widget/AnimatedAvatarIcon.dart';
import 'package:namekart_app/cutsom_widget/CustomShimmer.dart';
import 'package:namekart_app/cutsom_widget/TypewriterText.dart';
import 'package:namekart_app/screens/features/BiddingList.dart';
import 'package:namekart_app/screens/features/WatchList.dart';
import 'package:namekart_app/screens/home_screen/carousel_options/whatnewupdate/UpdateVersions.dart';
import 'package:namekart_app/screens/home_screen/drawer/ProfileDrawer.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:namekart_app/screens/notifications_screen/NotificationScreen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../activity_helpers/GlobalVariables.dart';
import '../../activity_helpers/UIHelpers.dart';
import '../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../cutsom_widget/customSyncWidget.dart';
import '../../database/HiveHelper.dart';
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

  bool bugReportButtonClicked = false;

  TextEditingController editingController = TextEditingController();

  String foundBugText = "";
  
  List<String> ringAlarmActiveList=[];

  late LiveDatabaseChange liveDatabaseChange;


  @override
  void initState() {
    super.initState();

    connectToWebsocket();

    editingController.addListener(getFoundBugText);

    getRingAlarmList();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifyRebuildChange = Provider.of<NotifyRebuildChange>(context, listen: false);

      notifyRebuildChange.notifyRebuild(); // ✅ just call, don't assign
      notifyRebuildChange.addListener(getRingAlarmList);
    });
  }


  Future<void> getRingAlarmList()async {
    setState(() {
      ringAlarmActiveList = HiveHelper.getRingAlarmPaths();
      ringAlarmActiveList = ringAlarmActiveList
          .where((e) => !e.startsWith("live~all")) // ✅ skip unwanted entries
          .map((e) => e.split("~").take(3).join("~"))
          .toSet()
          .toList();
    });
    }

  void getFoundBugText() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void connectToWebsocket() async {
    await WebSocketService().connect(
      GlobalProviders.userId,
      Provider.of<LiveDatabaseChange>(context, listen: false),
      Provider.of<LiveListDatabaseChange>(context, listen: false),
      Provider.of<NotificationDatabaseChange>(context, listen: false),
      Provider.of<NewNotificationTableAddNotifier>(context, listen: false),
      Provider.of<DatabaseDataUpdatedNotifier>(context, listen: false),
      Provider.of<NotifyRebuildChange>(context, listen: false),
    );

    final Map<String, dynamic> response =
        await WebSocketService().sendMessageGetResponse({
      "query": "reconnection-check",
    }, "user");

    final reconnected = response != null &&
        response.containsKey('data') &&
        jsonDecode(response['data'])['response']
            .toString()
            .contains("reconnected");

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
      body: AlertWidget(
        onReconnectSuccess: () {},
        path: '',
        child: RefreshIndicator(
          onRefresh: getRingAlarmList,
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                _buildAppBar(),
                Column(children: [
                  
                  if(ringAlarmActiveList.isNotEmpty)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          color:Colors.red,
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(20),bottomLeft: Radius.circular(20)),
                        border: Border.all(color: Colors.black,width: 2)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 15,left: 15,right: 15,bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Critical Error Occurred",style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12
                                ),),
                                Icon(Icons.arrow_right_alt_sharp,color: Colors.white,size: 20,)
                              ],
                            ),
                          ),
                          Wrap(
                            children: ringAlarmActiveList.map((item){
                              return Bounceable(
                                onTap: (){
                                  List<String> collections=item.split("~");
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>

                                      collections[0].contains("live")?LiveDetailsScreen(
                                      img: "assets/images/home_screen_images/livelogos/${collections[1]}.png",
                                      mainCollection: collections[0],
                                      subCollection: collections[1],
                                      subSubCollection: collections[2],
                                      showHighlightsButton: item.contains("live")?true:false):NotificationScreen()
                                  ));
                                },
                                child:Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Container(
                                    width: 150.sp,
                                    decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(10)),
                                    padding: EdgeInsets.all(10),
                                    child: TextScroll(item,style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 10
                                    ),
                                      velocity: Velocity(pixelsPerSecond: Offset(10, 0)),
                                      pauseBetween: Duration(seconds: 2),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 5,)
                        ],
                      ),
                    ),
                  
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
                                  textStyle: GoogleFonts.poppins().copyWith(
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
                          Bounceable(
                            onTap: () async {
          
                              _carouselCardsInfo(
                                "Found A Bug??",
                                "How does that bug occured ...",
                                "bug-reports"
                              );
                            },
                            child: _carouselCards(
                                "Spotted something wrong?",
                                "Tell us here!",
                                "assets/images/home_screen_images/foundabug.png",
                                Color(0xfff3f3f3),
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
                                Color(0xff3B3F4B),
                                Colors.white),
                          ),
                          Bounceable(
                            onTap: () {
                              Navigator.push(context, PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                return UpdateVersion();
                              }));
                            },
                            child: _carouselCards(
                                "We’ve Upgraded!",
                                "Find Out What’s Changed",
                                "assets/images/home_screen_images/weupgraded.png",
                                Color(0xffEFBF04),
                                Colors.white),
                          ),
                          _carouselCards(
                              "New Surprises Inside!",
                              "Check Out What’s Happening",
                              "assets/images/home_screen_images/newsurprise.png",
                              Color(0xffEFBF04),
                              Colors.white),
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
                                                  animation,
                                                  secondaryAnimation,
                                                  child) {
                                                const begin = Offset(0.0, 1.0);
                                                const end = Offset.zero;
                                                const curve = Curves.easeInOut;
                                                var tween = Tween(
                                                        begin: begin, end: end)
                                                    .chain(
                                                        CurveTween(curve: curve));
                                                var offsetAnimation =
                                                    animation.drive(tween);
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
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: Color(0xFFB71C1C),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(13),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0),
                                                      child: Text("Search",
                                                          style:
                                                              GoogleFonts.poppins(
                                                            fontWeight:
                                                                FontWeight.bold,
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
                            SizedBox(
                              height: 10,
                            )
                          ],
                        ),
                      )),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
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
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                      width: 310.sp,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            topRight: Radius.circular(20),
                            topLeft: Radius.circular(20)),
                      ),
                      child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: Duration(milliseconds: 300),
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
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
                                              begin: Offset(1, 0),
                                              end: Offset(0, 0))
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
                                  left: 20, right: 20, top: 20, bottom: 20),
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
                      width: MediaQuery.of(context).size.width,
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
                                              builder: (context) =>
                                                  BiddingList()));
                                    },
                                    child: _AuctionTools(
                                        "biddinglist", "Bidding List")),
                                GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => WatchList()));
                                    },
                                    child:
                                        _AuctionTools("watchlist", "Watch List")),
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
                                    child:
                                        _AuctionTools("bulkfetch", "Bulk Fetch")),
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
                      width: MediaQuery.of(context).size.width,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
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
                      width: MediaQuery.of(context).size.width,
                      height: 1,
                      color: Colors.black12,
                    ),
                  ),
                ]),
              ])),
        ),
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: ringAlarmActiveList.isEmpty?Colors.transparent:Colors.red,
        title: Row(
          children: [
            Image.asset(
              "assets/images/applogo-transparent.png",
              width: 30,
              height: 30,
              color: ringAlarmActiveList.isEmpty?null:Colors.white,
            ),
            const SizedBox(width: 8),
            Shimmer.fromColors(
              baseColor: ringAlarmActiveList.isEmpty?Color(0xFFFF0000):Colors.white,
              highlightColor:ringAlarmActiveList.isEmpty?Colors.white:Colors.black,
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
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
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
                child: Text(subTitle,
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
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
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

                              try {
                                final response =
                                    await w.sendMessageGetResponse({
                                  "query": websocketQuery.toString(),
                                  "message": foundBugText.toString(),
                                }, "user").timeout(Duration(seconds: 5));

                                // If response comes within 5 seconds
                                showTopSnackBar(
                                  Overlay.of(context),
                                  displayDuration: Duration(milliseconds: 100),
                                  animationDuration: Duration(seconds: 1),
                                  CustomSnackBar.success(
                                    message:
                                        response.toString().contains("success")
                                            ? "Send Bug Report Successfully"
                                            : "Failed To Send Bug Report!",
                                  ),
                                );
                              } on TimeoutException catch (_) {
                                // If no response within 5 seconds
                                showTopSnackBar(
                                  Overlay.of(context),
                                  displayDuration: Duration(milliseconds: 100),
                                  animationDuration: Duration(seconds: 1),
                                  CustomSnackBar.error(
                                    message: "Failed To Send Bug Report!",
                                  ),
                                );
                              }
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity:
                    CurvedAnimation(parent: animation, curve: Curves.easeIn),
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
