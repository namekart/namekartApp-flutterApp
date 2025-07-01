import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namekart_app/screens/features/BiddingList.dart';
import 'package:namekart_app/screens/features/WatchList.dart';
import 'package:namekart_app/screens/features/BulkBid.dart';
import 'package:namekart_app/screens/features/BulkFetch.dart';
import 'package:namekart_app/screens/home_screen/tabs/channels_tab.dart';
import 'package:namekart_app/screens/home_screen/tabs/profile_options/FirestoreInfo.dart';
import 'package:namekart_app/screens/live_screens/live_details_screen.dart';
import 'package:namekart_app/screens/search_screen/SearchScreen.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:provider/provider.dart';

import '../../../activity_helpers/FirestoreHelper.dart';
import '../../../activity_helpers/GlobalFunctions.dart';
import '../../../change_notifiers/AllDatabaseChangeNotifiers.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<String> ringAlarmActiveList = [];
  late NotificationDatabaseChange notificationDatabaseChange;

  int readDropcatch = 0;
  int readDynadot = 0;
  int readGodaddy = 0;
  int readNamecheap = 0;
  int readNamesilo = 0;
  int readSav = 0;

  @override
  void initState() {
    super.initState();
    getRingAlarmList();

    getReadCount();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clean up old listener if it exists
      notificationDatabaseChange =
          Provider.of<NotificationDatabaseChange>(context, listen: false);
      notificationDatabaseChange.addListener(getReadCount);
    });
  }

  void getReadCount() {
    setState(() {
      readGodaddy =
          HiveHelper.getUnreadCountFlexible("notifications~AMP-LIVE~Live-GD");
      readDynadot =
          HiveHelper.getUnreadCountFlexible("notifications~AMP-LIVE~Live-DD");
      readDropcatch =
          HiveHelper.getUnreadCountFlexible("notifications~AMP-LIVE~Live-DC");
      readNamecheap =
          HiveHelper.getUnreadCountFlexible("notifications~AMP-LIVE~Live-NC");
      readNamesilo =
          HiveHelper.getUnreadCountFlexible("notifications~AMP-LIVE~Live-NS");
      readSav =
          HiveHelper.getUnreadCountFlexible("notifications~AMP-LIVE~Live-SAV");
    });

    print(
        "readDropcatch: $readDropcatch, readDynadot: $readDynadot, readGodaddy: $readGodaddy, readNamecheap: $readNamecheap, readNamesilo: $readNamesilo, readSav: $readSav");
  }

  Future<void> getRingAlarmList() async {
    setState(() {
      ringAlarmActiveList = HiveHelper.getRingAlarmPaths()
          .where((e) => !e.startsWith("live~all"))
          .map((e) => e.split("~").take(3).join("~"))
          .toSet()
          .toList();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    ringAlarmActiveList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Color(0xffF7F7F7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          buildCriticalErrorBanner(
            context,
            ringAlarmActiveList,
            () => setState(() => ringAlarmActiveList.clear()),
          ),
          _buildSearchBar(context),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xffFFFFFF),
                border: Border.all(color: Colors.black12, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _sectionHeader("Live Status", onSeeAllTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LiveDetailsScreen(
                                img: "assets/images/bubbles_images/seeall.png",
                                mainCollection: "live",
                                subCollection: "all",
                                subSubCollection: "auctions",
                                showHighlightsButton: true,
                              )),
                    );
                  }),
                  _liveStatusRow(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
                decoration: BoxDecoration(
                  color: Color(0xffFFFFFF),
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _sectionHeader("Auction Tools"),
                    _auctionToolsRow(),
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text(
                    text: "Created For \nYou!",
                    size: 25.sp,
                    color: Color(0xffA8A7A7),
                    fontWeight: FontWeight.w600),
                text(
                    text: "By Namekart",
                    size: 12.sp,
                    color: Color(0xffA8A7A7),
                    fontWeight: FontWeight.w300),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Search()));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 0.5,
                  blurRadius: 0.5)
            ],
          ),
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              text(
                  text: "Find what you need faster",
                  fontWeight: FontWeight.w400,
                  color: Color(0xff717171),
                  size: 10.sp),
              Icon(Icons.search_rounded, color: Color(0xff717171), size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAllTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          text(
              text: title,
              size: 12.sp,
              color: Color(0xff3F3F41),
              fontWeight: FontWeight.w500),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: onSeeAllTap,
              child: text(
                  text: "",
                  fontWeight: FontWeight.bold,
                  color: Color(0xff717171),
                  size: 8.sp),
            )
        ],
      ),
    );
  }

  Widget _liveStatusRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Wrap(
        spacing: 40,
        runSpacing: 20,
        children: [
          _LiveStatusImage("livelogos/dropcatch", "Dropcatch"),
          _LiveStatusImage("livelogos/dynadot", "Dynadot"),
          _LiveStatusImage("livelogos/godaddy", "Godaddy"),
          _LiveStatusImage("livelogos/namecheap", "Namecheap"),
          _LiveStatusImage("livelogos/namesilo", "Namesilo"),
          SizedBox(width: 45, child: _LiveStatusImage("livelogos/sav", "SAV")),
        ],
      ),
    );
  }

  Widget _auctionToolsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Bounceable(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BiddingList())),
              child: _LiveStatusImage("features/biddinglist", "Bidding List")),
          Bounceable(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => WatchList())),
              child: _LiveStatusImage("features/watchlist", "Watch List")),
          Bounceable(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => BulkBid())),
              child: _LiveStatusImage("features/bulkbid", "Bulk Bid")),
          Bounceable(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BulkFetch())),
              child: _LiveStatusImage("features/bulkfetch", "Bulk Fetch")),
        ],
      ),
    );
  }

  Widget _LiveStatusImage(String image, String title) {
    String subSubCollectionName = image.contains("dropcatch")
        ? "Live-DC"
        : image.contains("dynadot")
            ? "Live-DD"
            : image.contains("godaddy")
                ? "Live-GD"
                : image.contains("namecheap")
                    ? "Live-NC"
                    : image.contains("sav")
                        ? "Live-SAV"
                        : image.contains("namesilo")
                            ? "Live-NS"
                            : "";

    String readCount = image.contains("dropcatch")
        ? readDropcatch.toString()
        : image.contains("dynadot")
            ? readDynadot.toString()
            : image.contains("godaddy")
                ? readGodaddy.toString()
                : image.contains("namecheap")
                    ? readNamecheap.toString()
                    : image.contains("sav")
                        ? readSav.toString()
                        : image.contains("namesilo")
                            ? readNamesilo.toString()
                            : "0";

    return image.contains("features")
        ? Column(
            children: [
              Image.asset(
                "assets/images/home_screen_images/$image.png",
                width: image.contains("livelogos") ? 25.sp : 20.sp,
                height: image.contains("livelogos") ? 25.sp : 20.sp,
                color: image.contains("livelogos") ? null : Colors.red,
              ),
              SizedBox(height: 10),
              text(
                  text: title,
                  size: 8,
                  color: Color(0xff717171),
                  fontWeight: FontWeight.w300),
            ],
          )
        : Bounceable(
            onTap: () async {
              if (image.contains("features")) return;
              await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LiveDetailsScreen(
                    img: "assets/images/home_screen_images/$image.png",
                    mainCollection: "notifications",
                    subCollection: "AMP-LIVE",
                    subSubCollection: subSubCollectionName,
                    showHighlightsButton: true,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                          parent: animation, curve: Curves.easeIn),
                      child: child,
                    );
                  },
                  transitionDuration: Duration(milliseconds: 350),
                ),
              );
              Future.delayed(const Duration(seconds: 1), () {
                getReadCount();
              });
            },
            child: Column(children: [
              Image.asset(
                "assets/images/home_screen_images/$image.png",
                width: image.contains("livelogos") ? 25.sp : 20.sp,
                height: image.contains("livelogos") ? 25.sp : 20.sp,
                color: image.contains("livelogos") ? null : Colors.red,
              ),
              SizedBox(height: 10),
              text(
                  text: title,
                  size: 8,
                  color: Color(0xff717171),
                  fontWeight: FontWeight.w300),
              if (readCount != "0") ...[
                SizedBox(
                  height: 5,
                ),
                Container(
                  child: text(
                      text: "$readCount New!",
                      size: 5.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w300),
                ),
              ],
            ]),
          );
  }

  Widget buildCriticalErrorBanner(
      BuildContext context, List<String> errors, VoidCallback onClear) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Critical Error Occurred",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                  Bounceable(
                    onTap: onClear,
                    child: Icon(Icons.hide_source_outlined,
                        size: 20, color: Colors.white),
                  )
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: errors.take(20).map((item) {
                final parts = item.split("~");
                final isLive = parts[0].contains("live");
                final imgPath =
                    "assets/images/home_screen_images/livelogos/${parts[1]}.png";

                return Bounceable(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => isLive
                              ? LiveDetailsScreen(
                                  img: imgPath,
                                  mainCollection: parts[0],
                                  subCollection: parts[1],
                                  subSubCollection: parts[2],
                                  showHighlightsButton: true)
                              : ChannelsTab()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: text(
                        text: item,
                        size: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.black),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
